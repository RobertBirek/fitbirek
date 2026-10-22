import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/workout_providers.dart';
import '../domain/workout_preparation.dart';
import '../providers/preparation_providers.dart';
import 'preparation_exercise_card.dart';

Future<bool?> showWorkoutPreparation(
  BuildContext context,
  WidgetRef ref, {
  required PreparationSnapshot snapshot,
}) {
  final workflow = ref.read(workoutPreparationWorkflowProvider);
  Widget sheet() =>
      WorkoutPreparationSheet(snapshot: snapshot, workflow: workflow);
  if (MediaQuery.sizeOf(context).width >= 840) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 760,
          height: MediaQuery.sizeOf(context).height * .9,
          child: sheet(),
        ),
      ),
    );
  }
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    clipBehavior: Clip.antiAlias,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height * .94 -
                    MediaQuery.viewInsetsOf(context).bottom)
                .clamp(160, double.infinity),
        child: sheet(),
      ),
    ),
  );
}

class WorkoutPreparationSheet extends ConsumerStatefulWidget {
  const WorkoutPreparationSheet({
    super.key,
    required this.snapshot,
    required this.workflow,
  });
  final PreparationSnapshot snapshot;
  final WorkoutPreparationWorkflow workflow;
  @override
  ConsumerState<WorkoutPreparationSheet> createState() =>
      _WorkoutPreparationSheetState();
}

class _WorkoutPreparationSheetState
    extends ConsumerState<WorkoutPreparationSheet> {
  late PreparationDraft _draft;
  final _form = GlobalKey<FormState>();
  bool _busy = false, _closed = false, _blocked = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _draft = PreparationDraft(widget.snapshot);
  }

  bool get _current =>
      mounted &&
      !_closed &&
      ref.read(cachedAuthWriteAuthorityProvider).epoch ==
          widget.snapshot.lease.epoch;

  void _close() {
    if (_busy) return;
    _closed = true;
    Navigator.of(context).pop(false);
  }

  Future<void> _start() async {
    if (_busy ||
        _blocked ||
        !_current ||
        _form.currentState?.validate() == false) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.workflow.start(_draft, isCurrent: () => _current);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _blocked = true;
          _error = ref.read(activeWorkoutProvider).isActive
              ? 'Trening jest już rozpoczęty. Zamknij podgląd i wybierz Kontynuuj trening.'
              : 'Start nie został zakończony. Zamknij podgląd i otwórz aktualny plan ponownie. Niedokończony trening znajdziesz przez Kontynuuj.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _replace(int index) async {
    if (_busy || !_current) return;
    final candidates = _draft.candidatesFor(index).where((e) {
      try {
        _draft.replace(index, e.id, ReplacementScope.sessionOnly);
        return true;
      } on StateError {
        return false;
      }
    }).toList();
    final id = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zamień ćwiczenie'),
        content: SizedBox(
          width: 520,
          child: candidates.isEmpty
              ? const Text(
                  'Brak zamienników spełniających warunki i dostępny sprzęt. Ograniczeń nie pominięto.',
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in candidates)
                      ListTile(
                        title: Text(e.nazwaPl),
                        subtitle: Text(
                          [
                            widget.snapshot.equipmentFor(e.id).join(', '),
                            if (widget.snapshot.matchingEquipment(e.id) == null)
                              'Brak zgodnego zestawu w profilu — lista informacyjna, brakujący sprzęt nadal wymagany.',
                          ].join(' · '),
                        ),
                        onTap: () => Navigator.pop(context, e.id),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
    if (id == null || !mounted || !_current) return;
    final scope = await showDialog<ReplacementScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gdzie zastosować zmianę?'),
        content: const Text(
          'Zmiany pozostają szkicem. Szablon zostanie zapisany dopiero po Rozpocznij trening.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, ReplacementScope.sessionOnly),
            child: const Text('Tylko ten trening'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, ReplacementScope.templateAndSession),
            child: const Text('Ten trening i szablon'),
          ),
        ],
      ),
    );
    if (scope == null || !_current) return;
    try {
      setState(() {
        _draft = _draft.replace(index, id, scope);
        _error = null;
      });
    } on StateError {
      if (mounted) {
        setState(
          () => _error =
              'Ta zmiana powieliłaby ćwiczenie w treningu lub szablonie. Wybierz inny zamiennik.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authority = ref.watch(cachedAuthWriteAuthorityProvider);
    final active = ref.watch(activeWorkoutProvider).isActive;
    return ValueListenableBuilder<int>(
      valueListenable: authority.revision,
      builder: (context, _, __) {
        final accountChanged = authority.epoch != widget.snapshot.lease.epoch;
        final enabled = !_busy && !_blocked && !accountChanged;
        final ids = widget.snapshot.plan == null
            ? widget.snapshot.exerciseIds
            : _draft.sessionPlan!.exerciseIds;
        final equipment = {
          for (final id in ids) ...widget.snapshot.equipmentFor(id),
        }.toList()..sort();
        final unsupported = [
          for (final id in ids)
            if (widget.snapshot.matchingEquipment(id) == null)
              widget.snapshot.exercise(id).nazwaPl,
        ];
        return PopScope(
          canPop: !_busy,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Przygotuj trening',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zamknij przygotowanie',
                        onPressed: _busy ? null : _close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: accountChanged
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Konto zmieniło się. Zamknij przygotowanie i otwórz je ponownie.',
                          ),
                        )
                      : Form(
                          key: _form,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  widget.snapshot.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontFamily: 'FitnessTestDisplay',
                                      ),
                                ),
                                if (widget.snapshot.plan != null)
                                  Text(
                                    '${ids.length} ćwiczeń · szacowany czas ${Formatters.duration(widget.snapshot.plan!.estimatedSeconds)}',
                                  ),
                                const SizedBox(height: 12),
                                if (ids.isEmpty)
                                  const Text(
                                    'Trening swobodny — plan nie jest wybrany. Ćwiczenia dodasz po rozpoczęciu.',
                                  )
                                else ...[
                                  Text(
                                    'Na początek: ${widget.snapshot.equipmentFor(ids.first).join(', ')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Sprzęt do treningu: ${equipment.join(', ')}',
                                  ),
                                  if (unsupported.isNotEmpty)
                                    Text(
                                      'Brak zgodnego zestawu w profilu: ${unsupported.join(', ')}. Podsumowanie sprzętu jest informacyjne; brakujący sprzęt nadal jest wymagany.',
                                    ),
                                  const Text(
                                    'Talerze są wspólne. Przy kolejnych ćwiczeniach może być potrzebne ich przełożenie.',
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (active && !_busy)
                                  const Text(
                                    'Masz rozpoczęty trening. Zamknij podgląd i wybierz Kontynuuj trening.',
                                  ),
                                if (widget.snapshot.plan == null &&
                                    ids.isNotEmpty) ...[
                                  const Text(
                                    'Starszy szablon zawiera tylko listę ćwiczeń. Nie dopisano celów; zamiany i serie ustalisz podczas treningu.',
                                  ),
                                  for (final id in ids)
                                    ListTile(
                                      title: Text(
                                        widget.snapshot.exercise(id).nazwaPl,
                                      ),
                                      subtitle: Text(
                                        widget.snapshot
                                            .equipmentFor(id)
                                            .join(', '),
                                      ),
                                    ),
                                ] else
                                  for (var i = 0; i < ids.length; i++)
                                    PreparationExerciseCard(
                                      key: ValueKey('$i:${ids[i]}'),
                                      draft: _draft,
                                      index: i,
                                      enabled: enabled,
                                      onTarget: (target) {
                                        if (_current && !_busy && !_blocked) {
                                          setState(
                                            () => _draft = _draft.setTarget(
                                              i,
                                              target,
                                            ),
                                          );
                                        }
                                      },
                                      onReplace: () => _replace(i),
                                    ),
                                if (_error != null)
                                  Semantics(
                                    liveRegion: true,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(_error!),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        label: 'Rozpocznij trening',
                        isLoading: _busy,
                        onPressed: enabled && !active ? _start : null,
                      ),
                      TextButton(
                        onPressed: _busy ? null : _close,
                        child: const Text('Anuluj'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
