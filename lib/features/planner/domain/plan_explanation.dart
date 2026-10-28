import '../../../core/models/exercise.dart';
import '../../../core/utils/partia_kategoria.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import 'structured_plan.dart';
import 'exercise_training_policy.dart';

/// Read-only explanations of current evidence, not persisted ranking provenance.
/// No I/O, medical assessment, selection or replacement authority.
abstract final class PlanExplanation {
  static String _labels(Iterable<String> values) {
    final sorted = values.toSet().toList()..sort();
    return sorted.isEmpty ? 'brak' : sorted.join(', ');
  }

  static String _pattern(Exercise e) =>
      ExerciseFilterEngine.fold(e.wzorzecRuchu).split(RegExp(r'[ +(]')).first;

  /// Uses saved criteria/level against the supplied current catalog. Equipment
  /// defaults to the snapshot; UI may pass the current equipment used by replace.
  /// Missing evidence fails closed; only matching OR alternatives are named.
  static List<String> forBlock({
    required StructuredPlan plan,
    required int index,
    required List<Exercise> allExercises,
    required ExerciseFilterEngine engine,
    List<String>? equipment,
  }) {
    final block = plan.blocks[index];
    final all = {for (final e in allExercises) e.id: e};
    final e = all[block.exerciseId];
    if (e == null) return const ['Niedostępne ćwiczenie w aktualnym katalogu.'];
    try {
      final pool = StructuredPlanGenerator.candidates(
        allExercises: allExercises,
        engine: engine,
        criteria: plan.criteria,
        equipment: equipment ?? plan.equipment,
        level: plan.level,
      );
      if (!pool.any((candidate) => candidate.id == e.id)) {
        return const [
          'Ćwiczenie nie należy do aktualnej puli zapisanych kryteriów, sprzętu i poziomu.',
        ];
      }
    } on StateError {
      return const [
        'Nie można zweryfikować kryteriów bez aktualnych metadanych.',
      ];
    }
    final f = plan.criteria;
    final metadata = engine.metadata;
    final entry = metadata.entryFor(e.id);
    final lines = <String>[
      'Spełnia zapisane kryteria puli.',
      'Sprzęt wymagany: ${_labels(e.sprzet)} — zgodny z ${equipment == null ? "zapisanym" : "aktualnym"} wyposażeniem.',
      'Poziom: ${e.poziom} ≤ ${plan.level}.',
      'Sekcja: ${block.section.label}.',
    ];
    void matched(String label, Iterable<String> values) {
      final list = values.toList();
      if (list.isNotEmpty) lines.add('$label: ${_labels(list)}.');
    }

    if (entry != null) {
      matched(
        'Styl / kolekcja',
        entry.styles.where(f.styles.contains).map(metadata.styleLabel),
      );
      matched('Mięśnie główne', entry.primaryMuscles.map(engine.muscleLabel));
      matched(
        'Mięśnie wspierające',
        entry.secondaryMuscles.map(engine.muscleLabel),
      );
      matched(
        'Warunki',
        entry.conditions
            .where(f.conditions.contains)
            .map(metadata.conditionLabel),
      );
      matched(
        'Pozycje',
        entry.positions.where(f.positions.contains).map(metadata.positionLabel),
      );
    } else {
      lines.add(
        'Brak metadanych mięśni i sposobu rejestrowania — bez domysłów.',
      );
    }
    if (engine.classificationAvailable) {
      matched(
        'Wybrane mięśnie',
        f.muscles
            .where(
              (id) =>
                  engine.filter([e], ExerciseFilters(muscles: {id})).isNotEmpty,
            )
            .map(engine.muscleLabel),
      );
    }
    matched('Wybrany sprzęt', e.sprzet.where(f.sprzet.contains));
    matched('Wybrany typ', [e.typ].where(f.typy.contains));
    matched('Wybrany poziom', [e.poziom].where(f.poziomy.contains));
    matched(
      'Wybrana partia',
      [
        mapToKategoria(e.partiaGlowna, wzorzecRuchu: e.wzorzecRuchu),
      ].where(f.partie.contains),
    );
    if (f.tylkoUlubione) lines.add('Ćwiczenie jest w ulubionych.');
    if (f.query.trim().isNotEmpty) {
      lines.add(
        'Wyszukiwanie: ${f.query.trim()} — pasuje do indeksu katalogu.',
      );
    }
    if (e.wzorzecRuchu.trim().isNotEmpty) {
      lines.add('Wzorzec ruchu: ${e.wzorzecRuchu}.');
    }
    // Preview order differs from generator reservation order. Never claim this
    // proves why the ranking selected a block (especially after replacement).
    final previous = plan.blocks
        .take(index)
        .map((b) => all[b.exerciseId])
        .toList();
    if (previous.isNotEmpty && previous.every((p) => p != null)) {
      final resolved = previous.cast<Exercise>();
      final pattern = _pattern(e);
      if (pattern.isNotEmpty &&
          resolved.every((p) => _pattern(p).isNotEmpty) &&
          !resolved.any((p) => _pattern(p) == pattern)) {
        lines.add(
          'Nowy wzorzec względem wcześniejszych bloków podglądu (pierwszy człon pola wzorca).',
        );
      }
      if (entry != null &&
          resolved.every((p) => metadata.entryFor(p.id) != null)) {
        final used = resolved.expand(engine.musclesFor).toSet();
        matched(
          'Dodatkowe mięśnie względem wcześniejszych bloków podglądu',
          engine.musclesFor(e).difference(used).map(engine.muscleLabel),
        );
      }
    }
    return List.unmodifiable(lines);
  }

  /// Describes a proposal; callers MUST obtain it from generator.replace and
  /// require explicit acceptance before changing state. No plan is modified.
  static List<String> forReplacement({
    required StructuredPlan plan,
    required StructuredPlan replacement,
    required int index,
    required List<Exercise> allExercises,
    required ExerciseFilterEngine engine,
    List<String>? equipment,
  }) {
    final old = plan.blocks[index], next = replacement.blocks[index];
    final all = {for (final e in allExercises) e.id: e};
    final a = all[old.exerciseId], b = all[next.exerciseId];
    final lines = <String>[
      'Zamiennik pochodzi z aktualnej filtrowanej puli. Zgodność wymaga tej samej sekcji, metryki, jednostronności, rozpoznanej rodziny ruchu i niepustych równych mięśni głównych; nie wymaga identycznej dawki ani czasu.',
      if (old.section == next.section) 'Ta sama sekcja: ${next.section.label}.',
      if (old.prescription.tracking == next.prescription.tracking)
        'Ten sam sposób rejestrowania: ${next.prescription.tracking}.',
      if (old.prescription.totalSeconds == next.prescription.totalSeconds)
        'Ten sam czas ESTYMOWANY: ${next.prescription.totalSeconds} s.',
    ];
    void compare(String label, String before, String after) {
      lines.add(
        before == after
            ? 'Bez zmian — $label: $after.'
            : '$label: $before → $after.',
      );
    }

    final before = old.prescription, after = next.prescription;
    compare(
      'Cały plan ESTYMOWANY',
      '${plan.estimatedSeconds} s',
      '${replacement.estimatedSeconds} s',
    );
    compare(
      'Budżet',
      '${plan.budgetSeconds} s',
      '${replacement.budgetSeconds} s',
    );
    compare(
      'Czas bloku ESTYMOWANY',
      '${before.totalSeconds} s',
      '${after.totalSeconds} s',
    );
    compare(
      'Ciężar indywidualny',
      before.weightKg == null ? 'brak' : '${before.weightKg} kg',
      after.weightKg == null ? 'brak' : '${after.weightKg} kg',
    );
    compare('Serie', '${before.sets}', '${after.sets}');
    if (before.reps != null || after.reps != null) {
      compare(
        'Powtórzenia',
        before.reps?.toString() ?? 'nie dotyczy',
        after.reps?.toString() ?? 'nie dotyczy',
      );
    }
    compare(
      'Praca ESTYMOWANA na serię (obie strony, jeśli jednostronne)',
      '${before.workSeconds} s',
      '${after.workSeconds} s',
    );
    compare(
      'Przerwa między seriami',
      '${before.restSeconds} s',
      '${after.restSeconds} s',
    );
    compare(
      'Przejście',
      '${before.transitionSeconds} s',
      '${after.transitionSeconds} s',
    );

    if (a != null && b != null) {
      compare('Sprzęt', _labels(a.sprzet), _labels(b.sprzet));
      final am = engine.metadata.entryFor(a.id),
          bm = engine.metadata.entryFor(b.id);
      if (am != null && bm != null) {
        lines.add(
          'Jednostronność: ${am.unilateral ? "tak" : "nie"} → ${bm.unilateral ? "tak" : "nie"}.',
        );
        if (ExerciseTrainingPolicy.compatible(
          source: a,
          candidate: b,
          engine: engine,
        )) {
          lines.add(
            'Zgodna rodzina ruchu: ${ExerciseTrainingPolicy.movementFamily(b)}; '
            'te same mięśnie główne: ${_labels(bm.primaryMuscles.map(engine.muscleLabel))}.',
          );
        } else {
          lines.add(
            'Nie potwierdzono zgodności ruchu — ta propozycja nie powinna być przyjęta.',
          );
        }
        compare(
          'Mięśnie główne',
          _labels(am.primaryMuscles.map(engine.muscleLabel)),
          _labels(bm.primaryMuscles.map(engine.muscleLabel)),
        );
        compare(
          'Mięśnie wspierające',
          _labels(am.secondaryMuscles.map(engine.muscleLabel)),
          _labels(bm.secondaryMuscles.map(engine.muscleLabel)),
        );
      } else {
        lines.add('Brak metadanych do porównania ról mięśni.');
      }
      compare(
        'Wzorzec ruchu',
        a.wzorzecRuchu.trim().isEmpty ? 'nieznany' : a.wzorzecRuchu,
        b.wzorzecRuchu.trim().isEmpty ? 'nieznany' : b.wzorzecRuchu,
      );
      compare('Poziom', a.poziom, b.poziom);
    } else {
      lines.add('Niedostępne dane ćwiczenia do porównania.');
    }
    lines.addAll(
      forBlock(
        plan: replacement,
        index: index,
        allExercises: allExercises,
        engine: engine,
        equipment: equipment,
      ),
    );
    return List.unmodifiable(lines);
  }
}
