import 'dart:convert';
import 'dart:io';

import 'package:fitbirek_training/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _faces = {
  400: 'Regular',
  500: 'Medium',
  600: 'SemiBold',
  700: 'Bold',
  800: 'ExtraBold',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('font license is bundled and provenance pins upstream bytes', () async {
    final license = await rootBundle.loadString('assets/fonts/LICENSE.txt');
    expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(license, contains('The Inter Project Authors'));
    final provenance = File('assets/fonts/PROVENANCE.txt').readAsStringSync();
    expect(provenance, contains('Font family: Inter'));
    expect(provenance, contains('Version: 4.1'));
    expect(
      provenance,
      contains(
        'https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip',
      ),
    );
    expect(
      provenance,
      contains(
        '9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e',
      ),
    );
    final sums = File('assets/fonts/SHA256SUMS').readAsLinesSync();
    for (final face in _faces.values) {
      expect(
        sums.where(
          (line) => RegExp(
            '^[a-f0-9]{64}  assets/fonts/Inter-$face\\.ttf\$',
          ).hasMatch(line),
        ),
        hasLength(1),
      );
    }
  });

  test('FontManifest bundles every Inter weight used by the UI', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<dynamic>;
    final inter = manifest.cast<Map<String, dynamic>>().singleWhere(
      (entry) => entry['family'] == 'Inter',
    );
    expect(inter['fonts'], [
      for (final face in _faces.entries)
        {'asset': 'assets/fonts/Inter-${face.value}.ttf', 'weight': face.key},
    ]);
  });

  for (final face in _faces.entries) {
    test('Inter ${face.key} is a real static TTF with Polish glyphs', () async {
      final bytes = await rootBundle.load(
        'assets/fonts/Inter-${face.value}.ttf',
      );
      expect(bytes.getUint32(0), 0x00010000);
      final tables = <String, int>{};
      for (var i = 0; i < bytes.getUint16(4); i++) {
        final record = 12 + 16 * i;
        final tag = String.fromCharCodes(
          List.generate(4, (j) => bytes.getUint8(record + j)),
        );
        tables[tag] = bytes.getUint32(record + 8);
      }
      expect(tables, isNot(contains('fvar')));
      expect(bytes.getUint16(tables['OS/2']! + 4), face.key);
      final cmap = tables['cmap']!;
      final subtables = <int>[];
      for (var i = 0; i < bytes.getUint16(cmap + 2); i++) {
        subtables.add(cmap + bytes.getUint32(cmap + 4 + i * 8 + 4));
      }
      for (final rune in 'ĄĆĘŁŃÓŚŹŻąćęłńóśźż'.runes) {
        expect(
          subtables.any((offset) => _hasGlyph(bytes, offset, rune)),
          isTrue,
          reason: 'Missing Polish U+${rune.toRadixString(16)}',
        );
      }
    });
  }

  testWidgets('both themes render Polish text without runtime Google Fonts', (
    tester,
  ) async {
    final previous = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = previous);
    for (final theme in [FitBirekTheme.dark, FitBirekTheme.light]) {
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Inter');
      expect(theme.primaryTextTheme.titleLarge!.fontFamily, 'Inter');
      expect(theme.appBarTheme.titleTextStyle!.fontFamily, 'Inter');
      expect(theme.appBarTheme.titleTextStyle!.fontSize, 22);
      expect(theme.appBarTheme.titleTextStyle!.fontWeight, FontWeight.w700);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Zażółć gęślą jaźń')),
            body: Column(
              children: [
                for (final weight in _faces.keys)
                  Text(
                    'ĄĆĘŁŃÓŚŹŻ ąćęłńóśźż',
                    style: TextStyle(
                      fontWeight: FontWeight.values[weight ~/ 100 - 1],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(
      File('lib/app/theme.dart').readAsStringSync(),
      isNot(contains('GoogleFonts')),
    );
  });
}

bool _hasGlyph(ByteData bytes, int offset, int rune) {
  final format = bytes.getUint16(offset);
  if (format == 12) {
    for (var i = 0; i < bytes.getUint32(offset + 12); i++) {
      final group = offset + 16 + i * 12;
      final start = bytes.getUint32(group);
      if (rune >= start && rune <= bytes.getUint32(group + 4)) {
        return bytes.getUint32(group + 8) + rune - start != 0;
      }
    }
  } else if (format == 4) {
    final count = bytes.getUint16(offset + 6) ~/ 2;
    final ends = offset + 14;
    final starts = ends + count * 2 + 2;
    final deltas = starts + count * 2;
    final ranges = deltas + count * 2;
    for (var i = 0; i < count; i++) {
      final start = bytes.getUint16(starts + i * 2);
      if (rune < start || rune > bytes.getUint16(ends + i * 2)) continue;
      final delta = bytes.getInt16(deltas + i * 2);
      final range = bytes.getUint16(ranges + i * 2);
      if (range == 0) return (rune + delta) & 0xffff != 0;
      final glyph = bytes.getUint16(
        ranges + i * 2 + range + (rune - start) * 2,
      );
      return glyph != 0 && (glyph + delta) & 0xffff != 0;
    }
  }
  return false;
}
