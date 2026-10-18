import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'bootstrap localizes engine fonts without disabling fallbacks or SW',
    () {
      final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
      expect('{{flutter_js}}'.allMatches(bootstrap), hasLength(1));
      expect('{{flutter_build_config}}'.allMatches(bootstrap), hasLength(1));
      expect('_flutter.loader.load('.allMatches(bootstrap), hasLength(1));
      expect(
        bootstrap,
        contains("new URL('font-fallbacks/', document.baseURI).href"),
      );
      expect(bootstrap, contains('fontFallbackBaseUrl:'));
      expect(bootstrap, contains('serviceWorkerSettings:'));
      expect(
        bootstrap,
        contains('serviceWorkerVersion: {{flutter_service_worker_version}}'),
      );
      expect(bootstrap, isNot(contains('disableFontFallback')));
      expect(bootstrap, isNot(contains('fonts.gstatic.com')));
    },
  );

  test(
    'engine-pinned mirror contains all 22 fonts and licenses with valid SHA',
    () async {
      final manifest =
          jsonDecode(
                File('web/font-fallbacks/manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['flutterVersion'], '3.35.4');
      final fonts = (manifest['fonts'] as List).cast<Map<String, dynamic>>();
      expect(fonts, hasLength(22));
      expect(fonts.map((font) => font['path']).toSet(), hasLength(22));
      expect(fonts.where((font) => font['family'] == 'Roboto'), hasLength(1));
      expect(
        fonts.where((font) => font['family'] == 'Noto Sans Symbols'),
        hasLength(1),
      );
      for (var i = 0; i < 6; i++) {
        expect(
          fonts.where((font) => font['family'] == 'Noto Sans Symbols 2 $i'),
          hasLength(1),
        );
      }
      for (var i = 0; i < 12; i++) {
        expect(
          fonts.where((font) => font['family'] == 'Noto Color Emoji $i'),
          hasLength(1),
        );
      }
      for (final font in fonts) {
        final path = font['path'] as String;
        expect(path, isNot(contains('..')));
        expect(manifest['upstreamBaseUrl'], 'https://fonts.gstatic.com/s/');
        final bytes = File('web/font-fallbacks/$path').readAsBytesSync();
        expect(_hasWoff2Header(bytes), isTrue, reason: path);
        expect(bytes.length, font['bytes'], reason: path);
        expect(
          File('web/font-fallbacks/${font['license']}').existsSync(),
          isTrue,
        );
      }
      // sha256sum is part of the Linux Docker verification environment. No new
      // Dart dependency or network service is needed to verify the real bytes.
      final sha = await Process.run('sha256sum', [
        '-c',
        'web/font-fallbacks/SHA256SUMS',
      ]);
      expect(sha.exitCode, 0, reason: '${sha.stdout}\n${sha.stderr}');
      final checksums = File(
        'web/font-fallbacks/SHA256SUMS',
      ).readAsStringSync();
      for (final font in fonts) {
        expect(
          checksums,
          contains('${font['sha256']}  web/font-fallbacks/${font['path']}\n'),
        );
      }
    },
  );

  test('note-entry Noto Sans fallback is real WOFF2, not a SPA HTML 200', () {
    const path =
        'notosans/v37/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99Y41P6zHtY.woff2';
    final file = File('web/font-fallbacks/$path');
    expect(file.existsSync(), isTrue);
    expect(_hasWoff2Header(file.readAsBytesSync()), isTrue);
    final manifest =
        jsonDecode(File('web/font-fallbacks/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final fonts = (manifest['fonts'] as List).cast<Map<String, dynamic>>();
    expect(
      fonts.singleWhere((font) => font['family'] == 'Noto Sans')['path'],
      path,
    );
  });

  test('font validation rejects HTML even with a successful HTTP status', () {
    final html200 = utf8.encode(
      '<!DOCTYPE html><html><head></head><body>SPA fallback</body></html>',
    );
    expect(_hasWoff2Header(html200), isFalse);
    expect(_hasWoff2Header(ascii.encode('wOF2')), isFalse);
  });

  test('emoji-only warning symbol resolves to the exact engine SC 69 shard', () {
    const path =
        'notosanssc/v37/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYkldv7JjxkkgFsFSSOPMOkySAZ73y9ViAt3acb8NexQ2w.87.woff2';
    final file = File('web/font-fallbacks/$path');
    expect(file.existsSync(), isTrue);
    final bytes = file.readAsBytesSync();
    expect(_hasWoff2Header(bytes), isTrue);
    expect(bytes.length, 5256);
    final manifest =
        jsonDecode(File('web/font-fallbacks/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final fonts = (manifest['fonts'] as List).cast<Map<String, dynamic>>();
    final sc = fonts.singleWhere((font) => font['family'] == 'Noto Sans SC 69');
    expect(sc['path'], path);
    expect(
      sc['sha256'],
      'e4b7e47d39dc977a198121b39c448c698a5ccb33f14a48d945e25d122f6904e8',
    );
    expect(sc['sampleCodePoints'], contains('U+26A0'));
    expect(
      File('web/font-fallbacks/${sc['license']}').readAsStringSync(),
      contains("Reserved Font Name 'Source'"),
    );
  });

  test('SHA-bound audit covers dropdown, symbols and fitness emoji', () {
    final manifest =
        jsonDecode(File('web/font-fallbacks/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final fonts = (manifest['fonts'] as List).cast<Map<String, dynamic>>();
    final audited = fonts
        .expand((font) => font['sampleCodePoints'] as List)
        .toSet();
    expect(
      audited,
      containsAll([
        'U+25BE',
        'U+2192',
        'U+2713',
        'U+26A0',
        'U+1F4AA',
        'U+1F3CB',
        'U+1F9D8',
        'U+1F525',
        'U+1F600',
      ]),
    );
    final provenance = File(
      'web/font-fallbacks/PROVENANCE.txt',
    ).readAsStringSync();
    expect(provenance, contains('d693b4b9dbac2acd4477aea4555ca6dcbea44ba2'));
    expect(
      provenance,
      contains(
        '943175bcbce99ea2655d021008fa75dbcced31e5ee207203bada3d133e46e887',
      ),
    );
    expect(
      File('web/font-fallbacks/OFL-Noto.txt').readAsStringSync(),
      contains('SIL OPEN FONT LICENSE Version 1.1'),
    );
    expect(
      File('web/font-fallbacks/Apache-2.0-Roboto.txt').readAsStringSync(),
      contains('Version 2.0, January 2004'),
    );
  });
}

bool _hasWoff2Header(List<int> bytes) {
  if (bytes.length < 48 ||
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'wOF2') {
    return false;
  }
  final header = ByteData.sublistView(Uint8List.fromList(bytes));
  return header.getUint32(8) == bytes.length && header.getUint16(12) > 0;
}
