#!/usr/bin/env python3
"""Read-only prepromotion checks. Never builds, pulls or promotes an image."""
import argparse
import json
import re
import subprocess
import uuid


# Executed by the image's own Python, not the host interpreter. No __main__
# worker/lifespan is run. All failures are reported without exception messages.
PROBE = r'''
import asyncio, contextlib, importlib, io, json, os, pathlib, socket, stat, sys
sys.dont_write_bytecode = True
stage = 'identity'
location = ''
activity_attempted = False
def forbidden(*args, **kwargs):
    global activity_attempted
    activity_attempted = True
    raise RuntimeError('image import attempted external activity')
def probe(role, expected_uid, expected_gid):
    global stage, location
    if (os.getuid(), os.getgid()) != (expected_uid, expected_gid):
        raise ValueError('identity mismatch')
    root = pathlib.Path('/app')
    app = root / 'app'
    stage = 'read'
    files = []
    def tree(path):
        global location
        location = str(path.relative_to(root))
        info = path.lstat()
        if stat.S_ISLNK(info.st_mode):
            raise ValueError('symlink')
        if stat.S_ISDIR(info.st_mode):
            if not os.access(path, os.R_OK | os.X_OK):
                raise PermissionError('directory')
            for child in sorted(path.iterdir()):
                if child.name != '__pycache__':
                    tree(child)
        elif stat.S_ISREG(info.st_mode):
            data = path.read_bytes()
            files.append(path)
            if path.suffix == '.py':
                compile(data, str(path), 'exec')
        else:
            raise ValueError('special file')
    if not os.access(root, os.R_OK | os.X_OK):
        raise PermissionError('app root')
    tree(app)
    paths = {p.relative_to(app).as_posix() for p in files}
    if not {'main.py', 'push/worker.py', 'push/transport.py', 'mentor/exercise_catalog.json'} <= paths:
        raise ValueError('missing required application file')
    if role == 'migration':
        for name in ['migrate.py', 'alembic.ini', 'migrations', 'requirements-dev.lock']:
            tree(root / name)
    stage = 'import'
    # Block actual I/O even if a future import acquires an unintended side effect.
    socket.create_connection = forbidden
    socket.getaddrinfo = forbidden
    socket.socket.connect = forbidden
    socket.socket.connect_ex = forbidden
    asyncio.run = forbidden
    asyncio.create_task = forbidden
    subprocess = importlib.import_module('subprocess')
    subprocess.Popen = forbidden
    sys.path.insert(0, str(root))
    modules = set()
    for path in paths:
        if path.endswith('.py'):
            parts = path[:-3].split('/')
            if parts[-1] == '__init__':
                parts.pop()
            modules.add('.'.join(['app'] + parts))
    for name in sorted(modules, key=lambda n: (n.count('.'), n)):
        location = name
        module = importlib.import_module(name)
        source = getattr(module, '__file__', None)
        if source is not None and not pathlib.Path(source).resolve().is_relative_to(app):
            raise ValueError('module from outside image application')
    if activity_attempted:
        raise RuntimeError('image import attempted external activity')
    return {'ok': True, 'uid': os.getuid(), 'gid': os.getgid(), 'files': len(files), 'modules': len(modules)}
try:
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        result = probe(*ARGUMENTS)
except BaseException as error:
    result = {'ok': False, 'stage': stage, 'location': location, 'error': type(error).__name__}
print(json.dumps(result, sort_keys=True))
sys.exit(0 if result['ok'] else 1)
'''


def check_images(runtime_image, migration_image):
    result = {'ok': False, 'checks': []}
    try:
        images = []
        for role, ref in [('runtime', runtime_image), ('migration', migration_image)]:
            inspected = subprocess.run(
                ['docker', 'image', 'inspect', '--format',
                 '{"id":{{json .Id}},"user":{{json .Config.User}}}', ref],
                capture_output=True, text=True, timeout=30, check=True,
            )
            meta = json.loads(inspected.stdout)
            if not re.fullmatch(r'sha256:[0-9a-f]{64}', meta['id']) or meta['user'] != 'app':
                raise ValueError('unapproved image identity')
            images.append((role, meta['id']))
        for role, image in images:
            for user, uid, gid in [('app', 100, 101), ('65532:65532', 65532, 65532)]:
                name = 'fit-image-gate-' + uuid.uuid4().hex
                args = [
                    'docker', 'run', '--rm', '-i', '--pull=never', '--name', name,
                    '--network', 'none', '--read-only', '--cap-drop', 'ALL',
                    '--security-opt', 'no-new-privileges:true', '--user', user,
                    '--workdir', '/app', '--entrypoint', 'python',
                    '-e', 'DATABASE_URL=postgresql+asyncpg://probe:probe@127.0.0.1:1/probe',
                    '-e', 'PUSH_ENABLED=false', image, '-B', '-',
                ]
                proof = {'role': role, 'imageId': image, 'uid': uid, 'gid': gid, 'ok': False}
                try:
                    code = 'ARGUMENTS = ' + repr((role, uid, gid)) + '\n' + PROBE
                    process = subprocess.run(args, input=code, capture_output=True, text=True, timeout=120)
                    data = json.loads(process.stdout)
                    proof['ok'] = (
                        process.returncode == 0 and data.get('ok') is True
                        and (data.get('uid'), data.get('gid')) == (uid, gid)
                        and type(data.get('files')) is int and data['files'] >= 4
                        and type(data.get('modules')) is int and data['modules'] >= 3
                    )
                    if proof['ok']:
                        proof.update(files=data['files'], modules=data['modules'])
                    else:
                        proof['error'] = 'imageProbeFailed'
                except (OSError, ValueError, subprocess.SubprocessError):
                    proof['error'] = 'imageProbeUnavailable'
                finally:
                    # A timed-out docker CLI can leave its container running.
                    subprocess.run(['docker', 'rm', '-f', name], capture_output=True, timeout=30)
                result['checks'].append(proof)
        result['ok'] = len(result['checks']) == 4 and all(c['ok'] for c in result['checks'])
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError):
        result['error'] = 'imageInspectionOrCleanupFailed'
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime-image', required=True)
    parser.add_argument('--migration-image', required=True)
    args = parser.parse_args()
    result = check_images(args.runtime_image, args.migration_image)
    print(json.dumps(result, sort_keys=True))
    return 0 if result['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
