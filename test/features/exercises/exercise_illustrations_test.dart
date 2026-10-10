import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/presentation/exercise_illustrations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedIllustrationIds = {'cw256', 'cw257', 'cw261', 'cw264', 'cw265'};

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

  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw001'), isNull);
  });

  test('maps cw265 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw265'), 'assets/exercises/cw265.webp');
  });

  test('maps cw261 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw261'), 'assets/exercises/cw261.webp');
  });

  test('maps cw257 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw257'), 'assets/exercises/cw257.webp');
  });

  test('maps cw264 to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw264'), 'assets/exercises/cw264.webp');
  });

  test('loads and decodes the cw261 illustration as 512x512', () async {
    final data = await rootBundle.load('assets/exercises/cw261.webp');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    addTearDown(codec.dispose);
    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);

    expect(frame.image.width, 512);
    expect(frame.image.height, 512);
  });

  test('loads and decodes the cw257 illustration as 512x512', () async {
    final data = await rootBundle.load('assets/exercises/cw257.webp');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    addTearDown(codec.dispose);
    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);

    expect(frame.image.width, 512);
    expect(frame.image.height, 512);
  });

  test('loads and decodes the cw264 illustration as 512x512', () async {
    final data = await rootBundle.load('assets/exercises/cw264.webp');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    addTearDown(codec.dispose);
    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);

    expect(frame.image.width, 512);
    expect(frame.image.height, 512);
  });

  test('loads and decodes the cw265 illustration as 512x512', () async {
    final data = await rootBundle.load('assets/exercises/cw265.webp');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    addTearDown(codec.dispose);
    final frame = await codec.getNextFrame();
    addTearDown(frame.image.dispose);

    expect(frame.image.width, 512);
    expect(frame.image.height, 512);
  });
}
