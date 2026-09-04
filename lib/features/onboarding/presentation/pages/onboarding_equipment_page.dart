import 'package:flutter/material.dart';
import '../../../../app/constants.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/primary_button.dart';

/// Ekran 3 onboardingu: wybór dostępnego sprzętu (checkboxy).
class OnboardingEquipmentPage extends StatefulWidget {
  const OnboardingEquipmentPage({
    super.key,
    required this.onFinish,
    required this.onBack,
    required this.initialSelection,
  });

  final void Function(List<String> selected) onFinish;
  final VoidCallback onBack;
  final List<String> initialSelection;

  @override
  State<OnboardingEquipmentPage> createState() =>
      _OnboardingEquipmentPageState();
}

class _OnboardingEquipmentPageState extends State<OnboardingEquipmentPage> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection.toSet();
    if (_selected.isEmpty) {
      _selected.add('Masa własna');
    }
  }

  static const _icons = {
    'Masa własna': Icons.accessibility_new,
    'Hantle': Icons.fitness_center,
    'Ławeczka': Icons.chair_alt,
    'Drążek': Icons.horizontal_rule,
    'Gumy oporowe': Icons.linear_scale,
    'Bieżnia': Icons.directions_run,
    'Skakanka': Icons.all_inclusive,
    'Krzesło': Icons.chair,
    'Ręcznik': Icons.dry_cleaning,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Twój sprzęt',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Zaznacz czym dysponujesz w domu - baza ćwiczeń dopasuje się do Ciebie',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: AppConstants.dostepnySprzetOpcje.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = AppConstants.dostepnySprzetOpcje[index];
                    final isSelected = _selected.contains(item);
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(item);
                          } else {
                            _selected.add(item);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? FitBirekColors.accent.withValues(alpha: 0.15)
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? FitBirekColors.accent
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _icons[item] ?? Icons.fitness_center,
                              color: isSelected
                                  ? FitBirekColors.accent
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Checkbox(
                              value: isSelected,
                              activeColor: FitBirekColors.accent,
                              onChanged: (_) {
                                setState(() {
                                  if (isSelected) {
                                    _selected.remove(item);
                                  } else {
                                    _selected.add(item);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Zakończ konfigurację',
                icon: Icons.check_circle_outline,
                onPressed: () => widget.onFinish(_selected.toList()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
