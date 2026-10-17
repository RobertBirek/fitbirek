import 'package:fitbirek_training/core/database/app_database.dart';

/// Remove current-only columns when constructing historical migration fixtures.
Future<void> removeV12Columns(AppDatabase db) async {
  for (final column in ['filter_presets_json', 'exercise_variants_json']) {
    await db.customStatement('ALTER TABLE user_profiles DROP COLUMN $column');
  }
  for (final table in ['sets_log', 'personal_records']) {
    for (final column in ['variant_id', 'variant_label']) {
      await db.customStatement('ALTER TABLE $table DROP COLUMN $column');
    }
  }
}
