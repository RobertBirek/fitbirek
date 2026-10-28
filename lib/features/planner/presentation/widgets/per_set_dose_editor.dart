import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/set_prescription.dart';
import '../../../../core/models/set_role.dart';

/// Editable controllers wrap the single immutable prescription model, not a
/// second serializer. Row movement retains this object and its target UUID.
class SetTargetForm {
  SetTargetForm(SetPrescription target)
    : targetId = target.targetId,
      role = target.setRole,
      side = target.side,
      amount = TextEditingController(text: '${target.reps ?? target.seconds}'),
      kg = TextEditingController(text: target.weightKg?.toString() ?? ''),
      rest = TextEditingController(text: '${target.restSeconds}'),
      work = TextEditingController(text: '${target.workSeconds}');
  final String targetId;
  String role;
  String? side;
  final TextEditingController amount, kg, rest, work;
  void dispose() {
    for (final c in [amount, kg, rest, work]) {
      c.dispose();
    }
  }

  SetPrescription build(String tracking) => SetPrescription(
    targetId: targetId,
    setRole: role,
    side: side,
    reps: tracking == 'reps' ? int.parse(amount.text) : null,
    seconds: tracking == 'time' ? int.parse(amount.text) : null,
    weightKg: kg.text.trim().isEmpty
        ? null
        : double.parse(kg.text.replaceAll(',', '.')),
    workSeconds: int.parse(work.text),
    restSeconds: int.parse(rest.text),
  )..validate(tracking);
  static SetTargetForm initial(String tracking, bool unilateral) =>
      SetTargetForm(
        SetPrescription(
          targetId: const Uuid().v4(),
          setRole: SetRole.working,
          side: unilateral ? 'both' : null,
          reps: tracking == 'reps' ? 10 : null,
          seconds: tracking == 'time' ? 40 : null,
          workSeconds: (tracking == 'reps' ? 30 : 40) * (unilateral ? 2 : 1),
          restSeconds: 30,
        ),
      );
}

class PerSetDoseEditor extends StatelessWidget {
  const PerSetDoseEditor({
    super.key,
    required this.targets,
    required this.tracking,
    required this.unilateral,
    required this.enabled,
    required this.onChanged,
  });
  final List<SetTargetForm> targets;
  final String tracking;
  final bool unilateral, enabled;
  final VoidCallback onChanged;

  Widget number(
    SetTargetForm t,
    String suffix,
    TextEditingController controller,
    String label, {
    bool zero = false,
    bool weight = false,
    int maximum = 5400,
    VoidCallback? changed,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextFormField(
      key: ValueKey('target-${t.targetId}-$suffix'),
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: weight),
      decoration: InputDecoration(labelText: label),
      onChanged: (_) {
        changed?.call();
        onChanged();
      },
      validator: (text) {
        if (weight && (text ?? '').trim().isEmpty) return null;
        final value = weight
            ? double.tryParse((text ?? '').replaceAll(',', '.'))
            : int.tryParse(text ?? '');
        if (value == null ||
            !value.isFinite ||
            value < (zero || weight ? 0 : 1) ||
            (!weight && value > maximum)) {
          return 'Podaj ${zero || weight ? 'nieujemną' : 'dodatnią'} liczbę${weight ? '' : ' całkowitą do $maximum'}.';
        }
        return null;
      },
    ),
  );

  void estimate(SetTargetForm t) {
    final amount = int.tryParse(t.amount.text);
    if (amount == null || amount < 1 || amount > 5400) return;
    t.work.text =
        '${amount * (tracking == 'reps' ? 3 : 1) * (unilateral && t.side == 'both' ? 2 : 1)}';
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < targets.length; i++)
        Container(
          key: ValueKey(targets[i].targetId),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seria ${i + 1} · ${SetRole.label(targets[i].role)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                children: [
                  IconButton(
                    key: ValueKey('target-${targets[i].targetId}-up'),
                    tooltip: 'Przesuń serię w górę',
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: !enabled || i == 0
                        ? null
                        : () {
                            final t = targets.removeAt(i);
                            targets.insert(i - 1, t);
                            onChanged();
                          },
                  ),
                  IconButton(
                    key: ValueKey('target-${targets[i].targetId}-down'),
                    tooltip: 'Przesuń serię w dół',
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: !enabled || i == targets.length - 1
                        ? null
                        : () {
                            final t = targets.removeAt(i);
                            targets.insert(i + 1, t);
                            onChanged();
                          },
                  ),
                  IconButton(
                    tooltip: 'Usuń serię',
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: !enabled || targets.length < 2
                        ? null
                        : () {
                            targets.removeAt(i).dispose();
                            onChanged();
                          },
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('target-${targets[i].targetId}-role'),
                initialValue: targets[i].role,
                isExpanded: true,
                isDense: false,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'Rodzaj serii'),
                items: [
                  for (final r in [SetRole.warmup, SetRole.working])
                    DropdownMenuItem(value: r, child: Text(SetRole.label(r))),
                ],
                onChanged: !enabled
                    ? null
                    : (r) {
                        targets[i].role = r!;
                        onChanged();
                      },
              ),
              if (unilateral)
                DropdownButtonFormField<String>(
                  key: ValueKey('target-${targets[i].targetId}-side'),
                  initialValue: targets[i].side ?? 'both',
                  isExpanded: true,
                  isDense: false,
                  itemHeight: null,
                  decoration: const InputDecoration(labelText: 'Strona celu'),
                  items: const [
                    DropdownMenuItem(
                      value: 'both',
                      child: Text('Obie — powtórzenia na stronę'),
                    ),
                    DropdownMenuItem(value: 'left', child: Text('Lewa')),
                    DropdownMenuItem(value: 'right', child: Text('Prawa')),
                  ],
                  onChanged: !enabled
                      ? null
                      : (s) {
                          targets[i].side = s;
                          estimate(targets[i]);
                          onChanged();
                        },
                ),
              number(
                targets[i],
                'amount',
                targets[i].amount,
                tracking == 'reps' ? 'Powtórzenia serii' : 'Czas serii (s)',
                maximum: tracking == 'reps' ? 1800 : 5400,
                changed: () => estimate(targets[i]),
              ),
              number(
                targets[i],
                'kg',
                targets[i].kg,
                'Ciężar serii (kg, opcjonalnie)',
                weight: true,
              ),
              number(
                targets[i],
                'rest',
                targets[i].rest,
                'Przerwa po serii (s)',
                zero: true,
              ),
              number(
                targets[i],
                'work',
                targets[i].work,
                'Praca ESTYMOWANA (s)',
              ),
              if (i == targets.length - 1)
                const Text(
                  'Po ostatniej serii czas przejścia zastępuje przerwę w estymacji.',
                ),
            ],
          ),
        ),
      OutlinedButton.icon(
        onPressed: !enabled || targets.length >= 100
            ? null
            : () {
                targets.add(SetTargetForm.initial(tracking, unilateral));
                onChanged();
              },
        icon: const Icon(Icons.add),
        label: const Text('Dodaj serię'),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ],
  );
}
