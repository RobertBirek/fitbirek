import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/presentation/exercise_illustrations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedIllustrationIds = {
    'cw251',
    'cw252',
    'cw253',
    'cw254',
    'cw255',
    'cw256',
    'cw257',
    'cw258',
    'cw259',
    'cw260',
    'cw261',
    'cw262',
    'cw263',
    'cw264',
    'cw265',
    'cw266',
    'cw267',
    'cw273',
    'cw274',
    'cw276',
    'cw277',
    'cw278',
    'cw279',
    'cw280',
    'cw281',
    'cw282',
    'cw283',
    'cw284',
    'cw285',
    'cw286',
    'cw287',
    'cw288',
    'cw289',
    'cw290',
    'cw291',
    'cw292',
    'cw293',
    'cw294',
    'cw295',
    'cw296',
    'cw297',
    'cw298',
    'cw299',
    'cw300',
    'cw301',
    'cw302',
    'cw303',
    'cw304',
    'cw305',
    'cw306',
    'cw307',
    'cw308',
    'cw309',
    'cw310',
    'cw311',
    'cw312',
    'cw313',
    'cw314',
    'cw315',
    'cw316',
  };

  test('registry contains exactly the illustration assets in the catalog', () {
    expect(illustratedExerciseIds, expectedIllustrationIds);

    for (final id in illustratedExerciseIds) {
      expect(
        exerciseIllustrationAsset(id),
        'assets/exercises/$id.webp',
        reason: id,
      );
    }
  });

  test('every illustration file is registered', () {
    final files = Directory('assets/exercises')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.webp'))
        .map((file) => file.uri.pathSegments.last)
        .toSet();

    expect(files, illustratedExerciseIds.map((id) => '$id.webp').toSet());
  });

  test('maps 90/90 hip stretch to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw256'), 'assets/exercises/cw256.webp');
  });

  test('maps cw251 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw251'), 'assets/exercises/cw251.webp');
  });

  test('maps cw252 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw252'), 'assets/exercises/cw252.webp');
  });

  test('maps cw253 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw253'), 'assets/exercises/cw253.webp');
  });

  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw001'), isNull);
  });

  test('maps cw265 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw265'), 'assets/exercises/cw265.webp');
  });

  test('maps cw261 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw261'), 'assets/exercises/cw261.webp');
  });

  test('maps cw262 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw262'), 'assets/exercises/cw262.webp');
  });

  test('maps cw257 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw257'), 'assets/exercises/cw257.webp');
  });

  test('maps cw264 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw264'), 'assets/exercises/cw264.webp');
  });

  test('maps cw278 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw278'), 'assets/exercises/cw278.webp');
  });

  test('loads and decodes every illustration as 512x512', () async {
    for (final id in illustratedExerciseIds) {
      final data = await rootBundle.load('assets/exercises/$id.webp');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      addTearDown(codec.dispose);
      final frame = await codec.getNextFrame();
      addTearDown(frame.image.dispose);

      expect(frame.image.width, 512, reason: id);
      expect(frame.image.height, 512, reason: id);
    }
  });
}
