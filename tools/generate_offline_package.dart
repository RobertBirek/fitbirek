// Build-host tool: no new Dart dependencies. SHA-256 uses coreutils sha256sum,
// already present in the pinned Linux Flutter builder (never a runtime command).
import 'dart:convert';
import 'dart:io';

String _hashFile(File file) {
  final result = Process.runSync('sha256sum', ['--', file.absolute.path]);
  if (result.exitCode != 0) throw StateError('sha256sum failed');
  final hash = result.stdout.toString().split(' ').first;
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
    throw StateError('Invalid SHA-256 output');
  }
  return hash;
}

String _hashJson(String root, Object value) {
  final temporary = File('$root/.offline-package-hash');
  try {
    temporary.writeAsStringSync(jsonEncode(value));
    return _hashFile(temporary);
  } finally {
    if (temporary.existsSync()) temporary.deleteSync();
  }
}

bool _included(String path) {
  final segments = path.split('/');
  if (segments.any(
    (part) =>
        part.startsWith('.') ||
        ['api', 'auth', 'export', 'exports'].contains(part),
  )) {
    return false;
  }
  return !path.endsWith('.map') &&
      !path.endsWith('.template') &&
      !path.endsWith('.gz') &&
      !path.endsWith('.br') &&
      ![
        'flutter_service_worker.js',
        'offline_package.json',
        'push/push-worker.js',
      ].contains(path);
}

bool _core(String path) =>
    [
      'index.html',
      'flutter_bootstrap.js',
      'flutter.js',
      'main.dart.js',
      'offline_client.js',
      'mentor_voice.js',
      'push/push-client.js',
      'manifest.json',
      'sqlite3.wasm',
      'drift_worker.dart.js',
      'assets/AssetManifest.bin',
      'assets/AssetManifest.bin.json',
      'assets/AssetManifest.json',
      'assets/FontManifest.json',
      'assets/assets/data/exercises.json',
    ].contains(path) ||
    path.startsWith('assets/fonts/') ||
    path.startsWith('assets/assets/fonts/') ||
    path.startsWith('font-fallbacks/roboto/') ||
    RegExp(r'^canvaskit/(chromium/)?canvaskit\.(js|wasm)$').hasMatch(path);

String generatePackage(Directory directory, {File? template}) {
  final root = directory.absolute.path.replaceFirst(RegExp(r'/+$'), '');
  for (final path in [
    'index.html',
    'main.dart.js',
    'flutter_bootstrap.js',
    'offline_client.js',
  ]) {
    final file = File('$root/$path');
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw StateError('Missing nonempty app shell: $path');
    }
  }
  // Identity of the whole build BEFORE adding identity markers, so neither hash
  // is recursive. Main-JS-only identity would conflate asset-only releases.
  // Also bypasses legacy Flutter's unversioned bootstrap cache on an online-first
  // HTML navigation. Re-running generation replaces the same marker deterministically.
  final index = File('$root/index.html');
  var html = index.readAsStringSync().replaceAll(
    RegExp(r'<meta name="fit-offline-shell" content="[a-f0-9]+">'),
    '',
  );
  html = html.replaceAll(
    RegExp(r'src="flutter_bootstrap\.js(?:\?[^"]*)?"'),
    'src="flutter_bootstrap.js"',
  );
  index.writeAsStringSync(html);
  final paths =
      directory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .map((file) => file.absolute.path.substring(root.length + 1))
          .where(_included)
          .toList()
        ..sort();
  final files = <Map<String, Object>>[];
  for (final path in paths) {
    final file = File('$root/$path');
    final bytes = file.lengthSync();
    files.add({
      'path': path.split('/').map(Uri.encodeComponent).join('/'),
      'bytes': bytes,
      'sha256': _hashFile(file),
    });
  }
  final core = paths
      .where(_core)
      .map((path) => path.split('/').map(Uri.encodeComponent).join('/'))
      .toList();
  final shellId = _hashJson(root, {'files': files, 'core': core});
  final marker = '<meta name="fit-offline-shell" content="$shellId">';
  html = html.contains('</head>')
      ? html.replaceFirst('</head>', '$marker</head>')
      : '$marker$html';
  html = html.replaceAll(
    'src="flutter_bootstrap.js"',
    'src="flutter_bootstrap.js?fit-shell=$shellId"',
  );
  index.writeAsStringSync(html);
  files[paths.indexOf('index.html')] = {
    'path': 'index.html',
    'bytes': index.lengthSync(),
    'sha256': _hashFile(index),
  };
  final totalBytes = files.fold<int>(
    0,
    (sum, file) => sum + (file['bytes'] as int),
  );
  final content = {
    'protocolVersion': 1,
    'shellId': shellId,
    'files': files,
    'core': core,
    'totalBytes': totalBytes,
  };
  // Hash canonical JSON without recursively including either generated artifact.
  final packageId = _hashJson(root, content);
  final manifest = {'packageId': packageId, ...content};
  final encoded = jsonEncode(manifest);
  File('$root/offline_package.json').writeAsStringSync('$encoded\n');
  final source = (template ?? File('web/offline_worker.js.template'))
      .readAsStringSync();
  if ('__FIT_OFFLINE_MANIFEST__'.allMatches(source).length != 1) {
    throw StateError('Expected exactly one worker manifest placeholder');
  }
  File(
    '$root/flutter_service_worker.js',
  ).writeAsStringSync(source.replaceFirst('__FIT_OFFLINE_MANIFEST__', encoded));
  // The template is a build input, not a public runtime resource.
  final copiedTemplate = File('$root/offline_worker.js.template');
  if (copiedTemplate.existsSync()) copiedTemplate.deleteSync();
  return packageId;
}

void main(List<String> arguments) {
  if (arguments.length > 1) {
    throw ArgumentError(
      'Usage: dart tools/generate_offline_package.dart [build/web]',
    );
  }
  final directory = Directory(
    arguments.isEmpty ? 'build/web' : arguments.single,
  );
  final id = generatePackage(directory);
  final manifest =
      jsonDecode(
            File('${directory.path}/offline_package.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  stdout.writeln(
    'Offline package $id: ${(manifest['files'] as List).length} files, ${manifest['totalBytes']} bytes',
  );
}
