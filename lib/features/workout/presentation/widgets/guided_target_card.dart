import 'package:flutter/material.dart';
import '../../../planner/domain/set_prescription.dart';
import '../../../planner/presentation/widgets/set_target_details.dart';

/// Keep the action separate from long details: even with large text and a
/// keyboard it has a reachable tap centre, unlike a viewport-sized ListTile.
class GuidedTargetCard extends StatelessWidget {
  const GuidedTargetCard({
    super.key,
    required this.target,
    required this.index,
    required this.selected,
    required this.status,
    required this.onSelect,
  });
  final SetPrescription target;
  final int index;
  final bool selected;
  final String status;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            selected: selected,
            child: OutlinedButton.icon(
              key: ValueKey('guided-target-${target.targetId}'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onSelect,
              icon: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              label: Text(
                '${selected ? 'Wybrany cel' : 'Wybierz cel'} ${index + 1}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(setTargetDetails(target)),
          Text(status, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    ),
  );
}
