import '../../../core/models/exercise.dart';
import '../../exercises/domain/exercise_catalog_metadata.dart';
import 'structured_plan.dart';

/// The JSON codec validates data shape; live metadata authorizes its meaning.
void validatePerSetCatalog(
  StructuredPlan plan,
  List<Exercise> catalog,
  ExerciseCatalogMetadata metadata,
) {
  if (plan.schemaVersion != 2) return;
  for (final block in plan.blocks) {
    final entry = metadata.entryFor(block.exerciseId);
    if (!catalog.any((e) => e.id == block.exerciseId) ||
        entry == null ||
        entry.tracking != block.prescription.tracking ||
        block.prescription.setTargets.any(
          (t) => entry.unilateral ? t.side == null : t.side != null,
        )) {
      throw StateError(
        'Ćwiczenie, metryka lub strona celu nie odpowiada aktualnemu katalogowi: ${block.exerciseId}. Niczego nie pominięto ani nie zamieniono.',
      );
    }
  }
}
