import 'dart:io';

import 'package:fitbirek_training/app/constants.dart';
import 'package:fitbirek_training/app/app_version.g.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UI version matches the full pubspec version including build', () {
    final version = RegExp(
      r'^version: (\S+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(AppConstants.appVersion, version);
    expect(AppVersion.full, version);
    expect('${AppVersion.name}+${AppVersion.buildNumber}', version);
  });

  testWidgets('settings info tile separates version and build from pubspec', (
    tester,
  ) async {
    final version = RegExp(
      r'^version: (\S+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
    final parts = version.split('+');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppInfoTile())),
    );
    expect(
      find.text(
        '${AppConstants.appName}\nWersja ${parts[0]} · build ${parts[1]}\nAutor: ${AppConstants.author}',
      ),
      findsOneWidget,
    );
  });
}
