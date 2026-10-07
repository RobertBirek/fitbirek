import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final script = File('tools/generate_app_version.dart').absolute.path;
  late Directory fixture;
  late File pubspec;
  late File output;

  ProcessResult run([List<String> args = const []]) => Process.runSync('dart', [
    script,
    ...args,
  ], workingDirectory: fixture.path);

  setUp(() {
    fixture = Directory.systemTemp.createTempSync('fit-version-test-');
    pubspec = File('${fixture.path}/pubspec.yaml');
    output = File('${fixture.path}/lib/app/app_version.g.dart');
  });
  tearDown(() => fixture.deleteSync(recursive: true));

  test('generates deterministic version and check does not write', () {
    pubspec.writeAsStringSync('name: fixture\nversion: 2.3.4+15\n');
    final result = run();
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final content = output.readAsStringSync();
    expect(content, contains("name = '2.3.4'"));
    expect(content, contains("buildNumber = '15'"));
    expect(content, contains("full = '2.3.4+15'"));
    final modified = output.lastModifiedSync();
    expect(run(['--check']).exitCode, 0);
    expect(output.lastModifiedSync(), modified);
    expect(run().exitCode, 0);
    expect(output.readAsStringSync(), content);
  });

  for (final entry in {
    'missing': 'name: fixture\n',
    'nested only': 'other:\n  version: 1.2.3+4\n',
    'duplicate': 'version: 1.2.3+4\nversion: 1.2.3+4\n',
    'empty': 'version:\n',
    'no build': 'version: 1.2.3\n',
    'bad name': 'version: 1.2+4\n',
    'bad build': 'version: 1.2.3+abc\n',
    'zero build': 'version: 1.2.3+0\n',
    'leading zero': 'version: 01.2.3+4\n',
    'prerelease': 'version: 1.2.3-beta+4\n',
    'trailing junk': 'version: 1.2.3+4 extra\n',
  }.entries) {
    test('rejects ${entry.key} without overwriting output', () {
      pubspec.writeAsStringSync(entry.value);
      output.parent.createSync(recursive: true);
      output.writeAsStringSync('keep');
      final result = run();
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('version'));
      expect(output.readAsStringSync(), 'keep');
    });
  }

  test('check detects missing and stale output without repairing it', () {
    pubspec.writeAsStringSync('version: 1.2.3+4\n');
    expect(run(['--check']).exitCode, isNot(0));
    expect(output.existsSync(), isFalse);
    expect(run().exitCode, 0);
    final old = output.readAsStringSync();
    pubspec.writeAsStringSync('version: 1.2.3+5\n');
    expect(run(['--check']).exitCode, isNot(0));
    expect(output.readAsStringSync(), old);
    expect(run().exitCode, 0);
    expect(run(['--check']).exitCode, 0);
  });

  test('rejects unsupported version overrides', () {
    pubspec.writeAsStringSync('version: 1.2.3+4\n');
    expect(run(['--build-name=9.9.9']).exitCode, isNot(0));
    expect(output.existsSync(), isFalse);
  });
}
