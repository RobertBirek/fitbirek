const illustratedExerciseIds = {'cw256', 'cw257', 'cw261', 'cw264', 'cw265'};

String? exerciseIllustrationAsset(String exerciseId) {
  return illustratedExerciseIds.contains(exerciseId)
      ? 'assets/exercises/$exerciseId.webp'
      : null;
}
