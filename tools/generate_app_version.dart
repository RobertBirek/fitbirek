import 'dart:io';

/// Intentionally accepts only the project's unquoted, top-level x.y.z+N field,
/// not arbitrary YAML. No package dependencies or CLI version overrides.
String generateVersionSource(String pubspec) {
  final fields = RegExp(
    r'^version\s*:([^\r\n]*)',
    multiLine: true,
  ).allMatches(pubspec).toList();
  if (fields.length != 1) {
    throw const FormatException(
      'Expected exactly one top-level version field.',
    );
  }
  final version = fields.single.group(1)!.trim();
  final match = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\+([1-9][0-9]*)$',
  ).firstMatch(version);
  if (match == null) {
    throw const FormatException(
      'Expected version: x.y.z+N (N > 0, no leading zeros).',
    );
  }
  final name = version.split('+').first;
  final build = match.group(4)!;
  return '''// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: pubspec.yaml; run dart tools/generate_app_version.dart.

abstract final class AppVersion {
  static const String name = '$name';
  static const String buildNumber = '$build';
  static const String full = '$version';
}
''';
}

void main(List<String> args) {
  if (args.isNotEmpty && (args.length != 1 || args.single != '--check')) {
    stderr.writeln('Usage: dart tools/generate_app_version.dart [--check]');
    exitCode = 64;
    return;
  }
  try {
    final expected = generateVersionSource(
      File('pubspec.yaml').readAsStringSync(),
    );
    final output = File('lib/app/app_version.g.dart');
    if (args.contains('--check')) {
      if (!output.existsSync() || output.readAsStringSync() != expected) {
        stderr.writeln(
          'App version is missing or stale. Run dart tools/generate_app_version.dart.',
        );
        exitCode = 1;
      }
      return;
    }
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(expected);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Cannot generate app version: $error');
    exitCode = 1;
  }
}
