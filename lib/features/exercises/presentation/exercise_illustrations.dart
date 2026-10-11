const illustratedExerciseIds = {
  'cw251',
  'cw252',
  'cw253',
  'cw256',
  'cw257',
  'cw261',
  'cw262',
  'cw264',
  'cw265',
  'cw278',
};

String? exerciseIllustrationAsset(String exerciseId) {
  return illustratedExerciseIds.contains(exerciseId)
      ? 'assets/exercises/$exerciseId.webp'
      : null;
}
