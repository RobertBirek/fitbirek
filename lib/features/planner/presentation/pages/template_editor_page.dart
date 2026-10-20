import 'dart:convert';
import 'dart:async';
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/widgets/content_layout.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../exercises/domain/exercise_filter_engine.dart';
import '../../domain/structured_plan.dart';
import '../../providers/planner_providers.dart';
import 'templates_page.dart';

/// Shared route payload for a session copy or a Mentor proposal. Never a write.
class TemplateEditorSeed {
  const TemplateEditorSeed(
    this.plan, {
    this.name = '',
    this.lease,
    this.updateLease,
  });
  final StructuredPlan plan;
  final String name;
  final TemplateLease? lease;

  /// Explicit session-to-existing replacement. Ordinary editing still loads
  /// the saved structure, while this path deliberately uses detached goals.
  final TemplateLease? updateLease;
}

class TemplateEditorPage extends ConsumerStatefulWidget {
  const TemplateEditorPage({super.key, this.syncId, this.seed});
  final String? syncId;
  final TemplateEditorSeed? seed;
  @override
  ConsumerState<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _Dose {
  _Dose(this.block)
    : sets = TextEditingController(text: '${block.prescription.sets}'),
      amount = TextEditingController(
        text: '${block.prescription.reps ?? block.prescription.workSeconds}',
      ),
      rest = TextEditingController(text: '${block.prescription.restSeconds}'),
      kg = TextEditingController(
        text: block.prescription.weightKg?.toString() ?? '',
      );
  final PlanBlock block;
  final TextEditingController sets, amount, rest, kg;
  bool expanded = true;
  void dispose() {
    sets.dispose();
    amount.dispose();
    rest.dispose();
    kg.dispose();
  }
}

class _TemplateEditorPageState extends ConsumerState<TemplateEditorPage> {
  final name = TextEditingController();
  final form = GlobalKey<FormState>();
  final doses = <_Dose>[];
  TemplateLease? lease;
  StructuredPlan? original;
  String query = '', error = '';
  bool busy = false, loading = true;
  VoidCallback? authorityListener;
  CachedAuthWriteAuthority? sourceAuthority;
  StreamSubscription<dynamic>? bindingSubscription;
  bool sourceInvalid = false;
  @override
  void initState() {
    super.initState();
    if (widget.seed?.lease != null) {
      final authority = ref.read(cachedAuthWriteAuthorityProvider);
      sourceAuthority = authority;
      authorityListener = () {
        if (authority.epoch != widget.seed!.lease!.epoch) clearPrivateSource();
      };
      authority.revision.addListener(authorityListener!);
      final db = ref.read(appDatabaseProvider);
      bindingSubscription = db
          .tableUpdates(TableUpdateQuery.onTable(db.syncState))
          .listen((_) async {
            final state = await db.syncDao.readState();
            if (!mounted) return;
            final source = widget.seed!.lease!;
            if (state?.accountId != source.accountId ||
                state?.deviceId != source.deviceId ||
                state?.offlineAccess != source.offlineAccess) {
              clearPrivateSource();
            }
          });
    }
    load();
  }

  void clearPrivateSource() {
    if (!mounted) return;
    setState(() {
      sourceInvalid = true;
      name.clear();
      for (final d in doses) {
        d.dispose();
      }
      doses.clear();
      original = null;
      lease = null;
      error =
          'Konto zmieniło się. Zamknij edytor i otwórz propozycję ponownie.';
    });
  }

  Future<void> load() async {
    try {
      final workflow = ref.read(plannerWorkflowProvider);
      final loaded =
          widget.seed?.lease ??
          await workflow.openTemplate(syncId: widget.syncId);
      await workflow.validateTemplateLease(loaded);
      final destination = widget.seed?.updateLease;
      if (destination != null) {
        await workflow.validateTemplateLease(destination);
      }
      if (!mounted) return;
      if (sourceInvalid ||
          (widget.seed?.lease != null &&
              ref.read(cachedAuthWriteAuthorityProvider).epoch !=
                  loaded.epoch)) {
        throw StateError('Konto zmieniło się. Otwórz propozycję ponownie.');
      }
      lease = destination ?? loaded;
      name.text = lease!.baseline?.nazwa ?? widget.seed?.name ?? '';
      final json = loaded.baseline?.structureJson;
      if (loaded.baseline != null && json == null) {
        throw StateError(
          'Starszy szablon nie ma celów. Utwórz nowy szablon i jawnie wybierz cele; dotychczasowy pozostaje bez zmian.',
        );
      }
      original = destination != null
          ? widget.seed!.plan
          : json == null
          ? widget.seed?.plan
          : StructuredPlan.fromJson(jsonDecode(json) as Map<String, dynamic>);
      doses.addAll((original?.blocks ?? <PlanBlock>[]).map(_Dose.new));
    } catch (e) {
      error = '$e';
      lease = null;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    if (authorityListener != null) {
      sourceAuthority!.revision.removeListener(authorityListener!);
    }
    bindingSubscription?.cancel();
    name.dispose();
    for (final d in doses) {
      d.dispose();
    }
    super.dispose();
  }

  void add(Exercise exercise) {
    final metadata = ref
        .read(exerciseCatalogMetadataProvider)
        .valueOrNull
        ?.entryFor(exercise.id);
    if (metadata == null || !{'reps', 'time'}.contains(metadata.tracking)) {
      setState(
        () => error =
            'To ćwiczenie nie ma obsługiwanego celu powtórzeń lub sekund. Nie zostało dodane.',
      );
      return;
    }
    setState(() {
      doses.add(
        _Dose(
          PlanBlock(
            exerciseId: exercise.id,
            section: PlanSection.main,
            prescription: PlanPrescription(
              tracking: metadata.tracking,
              sets: 3,
              reps: metadata.tracking == 'reps' ? 10 : null,
              workSeconds:
                  (metadata.tracking == 'reps' ? 30 : 40) *
                  (metadata.unilateral ? 2 : 1),
              restSeconds: 30,
              transitionSeconds: 15,
            ),
          ),
        ),
      );
      error = '';
    });
  }

  StructuredPlan buildPlan(List<Exercise> catalog) {
    final blocks = <PlanBlock>[];
    for (final dose in doses) {
      final p = dose.block.prescription;
      final metadata = ref
          .read(exerciseCatalogMetadataProvider)
          .requireValue
          .entryFor(dose.block.exerciseId);
      if (!catalog.any((e) => e.id == dose.block.exerciseId) ||
          metadata == null ||
          !{'reps', 'time'}.contains(metadata.tracking) ||
          metadata.tracking != p.tracking) {
        throw StateError(
          'Ćwiczenie lub jego sposób śledzenia jest niedostępny: ${dose.block.exerciseId}. Niczego nie pominięto.',
        );
      }
      final amount = int.parse(dose.amount.text);
      blocks.add(
        PlanBlock(
          exerciseId: dose.block.exerciseId,
          section: dose.block.section,
          prescription: PlanPrescription(
            tracking: p.tracking,
            sets: int.parse(dose.sets.text),
            reps: p.tracking == 'reps' ? amount : null,
            workSeconds: p.tracking == 'reps'
                ? (amount == p.reps
                      ? p.workSeconds
                      : amount * 3 * (metadata.unilateral ? 2 : 1))
                :
                  // Existing time targets already include both sides. Preserve their exact value.
                  amount,
            restSeconds: int.parse(dose.rest.text),
            transitionSeconds: p.transitionSeconds,
            weightKg: dose.kg.text.trim().isEmpty
                ? null
                : double.parse(dose.kg.text.replaceAll(',', '.')),
          ),
        ),
      );
    }
    final seconds = blocks.fold<int>(
      0,
      (s, b) => s + b.prescription.totalSeconds,
    );
    if (seconds > 5400) {
      throw const FormatException(
        'Czas ESTYMOWANY przekracza 90 min. Zmniejsz cele lub podziel szablon.',
      );
    }
    return StructuredPlan(
      criteria: original?.criteria ?? const ExerciseFilters(),
      budgetSeconds: math.max(
        300,
        math.max(original?.budgetSeconds ?? 300, (seconds / 60).ceil() * 60),
      ),
      blocks: blocks,
      warnings: original?.warnings ?? [],
      level: original?.level ?? 'Średni',
      equipment: original?.equipment ?? [],
    );
  }

  Future<void> save() async {
    if (busy) return;
    // Pola pozostają zamontowane przy zwijaniu. Otwórz błędne sekcje
    // przed validate, żeby komunikat nigdy nie został ukryty.
    setState(() {
      for (final d in doses) {
        if (invalidNumber(d.sets.text) != null ||
            invalidNumber(d.amount.text, maxInteger: amountLimit(d)) != null ||
            invalidNumber(d.rest.text, zero: true) != null ||
            invalidNumber(d.kg.text, weight: true) != null) {
          d.expanded = true;
        }
      }
    });
    if (!form.currentState!.validate() || lease == null) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final plan = buildPlan(ref.read(allExercisesProvider).requireValue);
      if (plan.blocks.isEmpty) {
        throw const FormatException('Dodaj co najmniej jedno ćwiczenie.');
      }
      if (!await confirmTemplateAction(
        context,
        lease!.baseline == null
            ? 'Zapisać nowy szablon?'
            : 'Zaktualizować szablon?',
        '${lease!.baseline == null ? '' : 'Zapis zastąpi cele istniejącego szablonu. '}Zapis celów nie tworzy sesji ani wykonanych serii i nie zmienia historii. Czas ESTYMOWANY: ${(plan.estimatedSeconds / 60).ceil()} min.',
      )) {
        return;
      }
      if (!mounted || lease == null || sourceInvalid) return;
      await ref
          .read(plannerWorkflowProvider)
          .saveTemplate(lease!, plan, name: name.text);
      if (mounted) context.go('/workout/templates');
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  int amountLimit(_Dose d) => d.block.prescription.tracking == 'reps'
      ? PlanPrescription.maxReps ~/
            (ref
                        .read(exerciseCatalogMetadataProvider)
                        .valueOrNull
                        ?.entryFor(d.block.exerciseId)
                        ?.unilateral ==
                    true
                ? 2
                : 1)
      : PlanPrescription.maxSeconds;

  String? invalidNumber(
    String? value, {
    bool zero = false,
    bool weight = false,
    int maxInteger = PlanPrescription.maxSeconds,
  }) {
    if (weight && (value ?? '').trim().isEmpty) return null;
    final n = weight
        ? double.tryParse((value ?? '').replaceAll(',', '.'))
        : int.tryParse(value ?? '');
    if (n == null || !n.isFinite || n < (zero || weight ? 0 : 1)) {
      return 'Podaj ${zero || weight ? 'nieujemną' : 'dodatnią'} liczbę${weight ? '' : ' całkowitą'}.';
    }
    if (!weight && n > maxInteger) {
      return 'Maksymalnie $maxInteger (limit szablonu: 90 min).';
    }
    return null;
  }

  Widget number(
    TextEditingController controller,
    String label, {
    bool zero = false,
    bool weight = false,
    int maxInteger = PlanPrescription.maxSeconds,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextFormField(
      controller: controller,
      enabled: !busy,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.numberWithOptions(decimal: weight),
      validator: (value) => invalidNumber(
        value,
        zero: zero,
        weight: weight,
        maxInteger: maxInteger,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (widget.seed?.lease != null &&
        ProviderScope.containerOf(
          context,
          listen: false,
        ).exists(authStateProvider)) {
      ref.listen(authStateProvider, (previous, next) {
        if (previous != next) clearPrivateSource();
      });
    }
    final catalog = ref.watch(allExercisesProvider);
    final metadata = ref.watch(exerciseCatalogMetadataProvider);
    final byId = {for (final e in catalog.valueOrNull ?? <Exercise>[]) e.id: e};
    final matches = byId.values
        .where(
          (e) =>
              !doses.any((d) => d.block.exerciseId == e.id) &&
              ExerciseFilterEngine.fold(
                '${e.nazwaPl} ${e.id}',
              ).contains(ExerciseFilterEngine.fold(query)),
        )
        .take(20);
    final selection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: name,
          enabled: !busy,
          decoration: const InputDecoration(labelText: 'Nazwa szablonu'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Podaj nazwę.' : null,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < doses.length; i++)
          Card(
            key: ObjectKey(doses[i]),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${i + 1}. ${byId[doses[i].block.exerciseId]?.nazwaPl ?? doses[i].block.exerciseId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      doses[i].sets,
                      doses[i].amount,
                      doses[i].kg,
                      doses[i].rest,
                    ]),
                    builder: (context, _) => Text(
                      '${doses[i].sets.text} × ${doses[i].amount.text}${doses[i].block.prescription.tracking == 'reps' ? ' powt.' : ' s'}${doses[i].kg.text.isEmpty ? '' : ' · ${doses[i].kg.text} kg'} · ${doses[i].rest.text} s przerwy',
                    ),
                  ),
                  Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Przesuń w górę',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: busy || i == 0
                            ? null
                            : () => setState(() {
                                final d = doses.removeAt(i);
                                doses.insert(i - 1, d);
                              }),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Przesuń w dół',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: busy || i == doses.length - 1
                            ? null
                            : () => setState(() {
                                final d = doses.removeAt(i);
                                doses.insert(i + 1, d);
                              }),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton(
                        tooltip: 'Usuń ćwiczenie',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                doses.removeAt(i).dispose();
                              }),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  Semantics(
                    expanded: doses[i].expanded,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        visualDensity: VisualDensity.standard,
                      ),
                      onPressed: busy
                          ? null
                          : () => setState(
                              () => doses[i].expanded = !doses[i].expanded,
                            ),
                      icon: Icon(
                        doses[i].expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      label: const Text('Parametry ćwiczenia'),
                    ),
                  ),
                  Offstage(
                    offstage: !doses[i].expanded,
                    child: Column(
                      children: [
                        number(doses[i].sets, 'Serie'),
                        number(
                          doses[i].amount,
                          doses[i].block.prescription.tracking == 'reps'
                              ? 'Powtórzenia'
                              : 'Sekundy (łącznie obie strony)',
                          maxInteger: amountLimit(doses[i]),
                        ),
                        number(
                          doses[i].rest,
                          'Przerwa między seriami (s)',
                          zero: true,
                        ),
                        number(
                          doses[i].kg,
                          'Ciężar (kg, opcjonalnie)',
                          weight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    final picker = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          enabled: !busy,
          decoration: const InputDecoration(labelText: 'Szukaj ćwiczenia'),
          onChanged: (v) => setState(() => query = v),
        ),
        if (catalog.hasError || metadata.hasError)
          const Text('Nie można wczytać katalogu. Ponów otwarcie edytora.'),
        if (catalog.isLoading || metadata.isLoading)
          const LinearProgressIndicator(),
        for (final e in matches)
          ListTile(
            title: Text(e.nazwaPl),
            trailing: IconButton(
              tooltip: 'Dodaj ćwiczenie',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy || !metadata.hasValue ? null : () => add(e),
              icon: const Icon(Icons.add),
            ),
          ),
        const Text(
          'Wyszukiwanie pokazuje do 20 wyników. Zawęź nazwę, aby znaleźć kolejne.',
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.syncId == null && widget.seed?.updateLease == null
              ? 'Nowy szablon'
              : 'Edytuj szablon',
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: form,
              child: Column(
                children: [
                  Expanded(
                    child: ContentLayout(
                      maxWidth:
                          MediaQuery.sizeOf(context).width >= 1000 &&
                              MediaQuery.textScalerOf(context).scale(16) <= 20
                          ? 1100
                          : 640,
                      child: SingleChildScrollView(
                        padding: ContentLayout.pagePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Cele, nie wykonanie. Czas ESTYMOWANY: 3 s/powtórzenie, obie strony dla ćwiczeń jednostronnych. Limit szablonu: 90 min.',
                            ),
                            if (error.isNotEmpty)
                              Text(
                                error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            for (final warning
                                in original?.warnings ?? <String>[])
                              Text(warning),
                            if (lease != null) ...[
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (MediaQuery.sizeOf(context).width >=
                                          1000 &&
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(16) <=
                                          20) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 3, child: selection),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 2, child: picker),
                                      ],
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      selection,
                                      const Divider(height: 32),
                                      picker,
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (lease != null)
                    SafeArea(
                      top: false,
                      child: ContentLayout(
                        maxWidth: 640,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              visualDensity: VisualDensity.standard,
                            ),
                            onPressed:
                                busy || !catalog.hasValue || !metadata.hasValue
                                ? null
                                : save,
                            child: Text(
                              busy ? 'Zapisywanie…' : 'Zapisz szablon',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
