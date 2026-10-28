import 'package:flutter/material.dart';
import '../../domain/structured_plan.dart';

/// Only valid, wire-safe proposals leave this dialog. A larger budget always
/// needs a separate affirmative choice, not just the generic accept action.
class PlanEditDialog extends StatefulWidget {
  const PlanEditDialog({
    super.key,
    required this.plan,
    required this.title,
    required this.acceptLabel,
    required this.propose,
    this.initialRest,
    this.explain,
  });
  final StructuredPlan plan;
  final String title, acceptLabel;
  final int? initialRest;
  final StructuredPlan? Function(int? rest) propose;
  final String Function(StructuredPlan proposal)? explain;

  @override
  State<PlanEditDialog> createState() => _PlanEditDialogState();
}

class _PlanEditDialogState extends State<PlanEditDialog> {
  late final _rest = TextEditingController(
    text: widget.initialRest?.toString(),
  );
  bool _increase = false;
  @override
  void dispose() {
    _rest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rest = int.tryParse(_rest.text);
    final valid =
        widget.initialRest == null ||
        (RegExp(r'^\d+$').hasMatch(_rest.text) && rest != null && rest <= 600);
    final proposal = valid ? widget.propose(rest) : null;
    final larger =
        proposal != null && proposal.budgetSeconds > widget.plan.budgetSeconds;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.initialRest != null)
              TextField(
                controller: _rest,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Przerwa między seriami (s)',
                  errorText: valid
                      ? null
                      : 'Wpisz całkowite sekundy od 0 do 600.',
                ),
                onChanged: (_) => setState(() => _increase = false),
              ),
            if (proposal != null) ...[
              Text(
                'Cały plan ESTYMOWANY: ${widget.plan.estimatedSeconds} s → ${proposal.estimatedSeconds} s '
                '(różnica ${proposal.estimatedSeconds - widget.plan.estimatedSeconds} s).',
              ),
              Text(
                'Budżet: ${widget.plan.budgetSeconds} s → ${proposal.budgetSeconds} s.',
              ),
              if (widget.explain != null) Text(widget.explain!(proposal)),
              if (larger)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Zgadzam się na zwiększenie budżetu (maks. 90 min).',
                  ),
                  value: _increase,
                  onChanged: (v) => setState(() => _increase = v == true),
                ),
            ] else if (valid)
              const Text(
                'Zmiana przekracza maksymalny budżet 90 min. Pozostałych bloków nie zmieniono.',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: proposal == null || (larger && !_increase)
              ? null
              : () => Navigator.pop(context, proposal),
          child: Text(widget.acceptLabel),
        ),
      ],
    );
  }
}
