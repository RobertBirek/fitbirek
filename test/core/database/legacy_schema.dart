import 'package:fitbirek_training/core/database/app_database.dart';

Future<void> removeV14Columns(AppDatabase db) async {
  await db.customStatement(
    'ALTER TABLE user_profiles DROP COLUMN fitness_protocols_json',
  );
  await db.customStatement(
    'ALTER TABLE fitness_test_results DROP COLUMN custom_protocol_json',
  );
}

/// Construct v12 (or earlier) without the v13 extension. Do not make this
/// idempotent: an unexpected fixture shape must fail instead of hiding a bug.
Future<void> removeV13Columns(AppDatabase db) async {
  await removeV14Columns(db);
  await db.customStatement(
    'ALTER TABLE user_profiles DROP COLUMN weekly_schedule_json',
  );
}

/// Remove v12 and later columns when constructing pre-v12 fixtures.
Future<void> removeV12Columns(AppDatabase db) async {
  await removeV13Columns(db);
  for (final column in ['filter_presets_json', 'exercise_variants_json']) {
    await db.customStatement('ALTER TABLE user_profiles DROP COLUMN $column');
  }
  for (final table in ['sets_log', 'personal_records']) {
    for (final column in ['variant_id', 'variant_label']) {
      await db.customStatement('ALTER TABLE $table DROP COLUMN $column');
    }
  }
}
