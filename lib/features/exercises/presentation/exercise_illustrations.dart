String? exerciseIllustrationAsset(String exerciseId) {
  return switch (exerciseId) {
    'cw256' => 'assets/exercises/cw256.webp',
    _ => null,
  };
}
