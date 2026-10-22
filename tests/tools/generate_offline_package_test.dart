import 'dart:convert';
import 'dart:io';

import '../../tools/generate_offline_package.dart' as generator;

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final directory = Directory.systemTemp.createTempSync('fit-offline-test-');
  try {
    void write(String path, String value) {
      final file = File('${directory.path}/$path');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(value);
    }

    write(
      'index.html',
      '<html><head></head><body><script src="flutter_bootstrap.js"></script></body></html>',
    );
    write('main.dart.js', 'application');
    write('flutter_bootstrap.js', 'bootstrap');
    write('offline_client.js', 'bridge');
    write('assets/assets/exercises/cw001.webp', 'image');
    write('font-fallbacks/font.woff2', 'font');
    write('sqlite3.wasm', 'wasm');
    write(
      'assets/assets/data/exercise_catalog_corrections.json',
      '{"schemaVersion":1,"corrections":[]}',
    );
    write(
      'assets/assets/data/exercise_catalog_metadata.json',
      '{"schemaVersion":1}',
    );
    write('canvaskit/canvaskit.wasm', 'canvas');
    write('main.dart.js.map', 'source map');
    write('api/private.json', 'private');
    write('push/push-worker.js', 'other worker');
    write('flutter_service_worker.js', 'old generated worker');
    write('offline_worker.js.template', 'source template');
    final first = generator.generatePackage(directory);
    final manifestText = File(
      '${directory.path}/offline_package.json',
    ).readAsStringSync();
    final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
    final shell = File('${directory.path}/index.html').readAsStringSync();
    check(shell.contains('name="fit-offline-shell"'), 'shell identity marker');
    check(shell.contains('?fit-shell='), 'legacy-safe bootstrap URL');
    final files = (manifest['files'] as List).cast<Map<String, dynamic>>();
    final paths = files.map((file) => file['path']).toList();
    check(
      paths.contains('assets/assets/exercises/cw001.webp'),
      'images included',
    );
    check(paths.contains('font-fallbacks/font.woff2'), 'fonts included');
    check(
      !paths.any((path) => path.toString().contains('api/')),
      'API excluded',
    );
    check(
      !paths.any((path) => path.toString().contains('worker')),
      'workers/templates excluded',
    );
    check(!paths.contains('main.dart.js.map'), 'source maps excluded');
    check(
      !paths.contains('offline_package.json'),
      'manifest cannot hash itself',
    );
    check(
      (manifest['core'] as List).contains('index.html'),
      'core includes shell',
    );
    check(
      (manifest['core'] as List).contains(
        'assets/assets/data/exercise_catalog_corrections.json',
      ),
      'required catalog corrections must be available before full-package consent',
    );
    check(
      (manifest['core'] as List).contains(
        'assets/assets/data/exercise_catalog_metadata.json',
      ),
      'equipment alternatives and preparation metadata must survive a core-only offline start',
    );
    check(
      !(manifest['core'] as List).contains(
        'assets/assets/exercises/cw001.webp',
      ),
      'full images require consent',
    );
    check(
      files.every((file) => (file['sha256'] as String).length == 64),
      'SHA256',
    );
    check(
      files.firstWhere((file) => file['path'] == 'main.dart.js')['bytes'] == 11,
      'actual bytes',
    );
    check(
      files.firstWhere((file) => file['path'] == 'main.dart.js')['sha256'] ==
          '1fe289205936c3fdb61158223892c7a8bee6ff4dfa085ea1c094ce0294e32114',
      'known SHA-256 vector',
    );
    check(first == generator.generatePackage(directory), 'stable package id');
    check(
      first == generator.generatePackage(Directory('${directory.path}/')),
      'trailing directory separator does not change package',
    );
    check(
      manifestText ==
          File('${directory.path}/offline_package.json').readAsStringSync(),
      'stable output despite prior generation',
    );
    write('font-fallbacks/font.woff2', 'changed font, unchanged executable');
    check(
      first != generator.generatePackage(directory),
      'asset changes package',
    );
    final assetChanged =
        jsonDecode(
              File('${directory.path}/offline_package.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    check(
      manifest['shellId'] != assetChanged['shellId'],
      'document identity must change even if only assets change',
    );
    write('font-fallbacks/font.woff2', 'font');
    check(
      first == generator.generatePackage(directory),
      'restored build identity',
    );
    write('main.dart.js', 'changed');
    check(first != generator.generatePackage(directory), 'content changes id');
    File('${directory.path}/index.html').deleteSync();
    var rejected = false;
    try {
      generator.generatePackage(directory);
    } on StateError {
      rejected = true;
    }
    check(rejected, 'missing app shell fails generation');
    stdout.writeln(
      'PASS: deterministic manifest, hashes, sizes, exclusions, shell validation',
    );
  } finally {
    directory.deleteSync(recursive: true);
  }
}
