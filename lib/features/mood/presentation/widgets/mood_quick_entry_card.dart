import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../providers/mood_providers.dart';

/// Widget szybkiego wpisu dziennika samopoczucia - 5 suwaków na ekranie "Dziś".
class MoodQuickEntryCard extends ConsumerStatefulWidget {
  const MoodQuickEntryCard({super.key});

  @override
  ConsumerState<MoodQuickEntryCard> createState() => _MoodQuickEntryCardState();
}

class _MoodQuickEntryCardState extends ConsumerState<MoodQuickEntryCard> {
  double _sen = 7;
  double _energia = 6;
  double _nastroj = 6;
  double _apetyt = 6;
  bool _alkohol = false;
  double _jednostki = 0;
  bool _saved = false;

  Future<void> _save() async {
    final repo = ref.read(moodRepositoryProvider);
    await repo.addEntry(
      snGodziny: _sen,
      energia: _energia.round(),
      nastroj: _nastroj.round(),
      apetyt: _apetyt.round(),
      alkohol: _alkohol,
      alkoholJednostki: _jednostki.round(),
    );
    setState(() => _saved = true);
    ref.invalidate(todayMoodEntryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayMoodEntryProvider);

    return todayAsync.when(
      data: (entry) {
        if (entry != null || _saved) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: FitBirekColors.success),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Dziennik samopoczucia wypełniony na dziś ✓'),
                  ),
                ],
              ),
            ),
          );
        }
        final ostrzezenieSen = _sen < 6;
        final ostrzezenieAlkohol = _alkohol && _jednostki > 2;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jak się czujesz dziś?',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildSlider('Sen (h)', _sen, 0, 12, (v) => setState(() => _sen = v),
                    warning: ostrzezenieSen),
                _buildSlider('Energia', _energia, 1, 10, (v) => setState(() => _energia = v)),
                _buildSlider('Nastrój', _nastroj, 1, 10, (v) => setState(() => _nastroj = v)),
                _buildSlider('Apetyt', _apetyt, 1, 10, (v) => setState(() => _apetyt = v)),
                Row(
                  children: [
                    Checkbox(
                      value: _alkohol,
                      onChanged: (v) => setState(() => _alkohol = v ?? false),
                    ),
                    const Text('Alkohol'),
                    if (_alkohol) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _jednostki,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _jednostki.round().toString(),
                          onChanged: (v) => setState(() => _jednostki = v),
                        ),
                      ),
                    ],
                  ],
                ),
                if (ostrzezenieAlkohol)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '⚠️ Duża ilość alkoholu może wpłynąć na regenerację',
                      style: TextStyle(color: FitBirekColors.warning, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Zapisz', onPressed: _save),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool warning = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toStringAsFixed(label == 'Sen (h)' ? 1 : 0),
              style: TextStyle(
                color: warning ? FitBirekColors.danger : FitBirekColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
