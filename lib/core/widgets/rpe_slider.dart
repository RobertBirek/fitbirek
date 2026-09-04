import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Suwak RPE (Rate of Perceived Exertion) 1-10 - subiektywna ocena
/// intensywności wykonanej serii. Kolor zmienia się wraz z wartością.
class RpeSlider extends StatelessWidget {
  const RpeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  Color _colorForRpe(int rpe) {
    if (rpe <= 4) return FitBirekColors.success;
    if (rpe <= 7) return FitBirekColors.warning;
    return FitBirekColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForRpe(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RPE (odczuwana intensywność)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value/10',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: value.toString(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
