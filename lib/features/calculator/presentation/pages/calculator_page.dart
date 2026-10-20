import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/utils/bmr_calculator.dart';
import '../../../onboarding/providers/user_profile_provider.dart';

/// Kalkulator BMR/TDEE/makro na podstawie profilu użytkownika.
class CalculatorPage extends ConsumerWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator kalorii/makro')),
      body: profileAsync.when(
        data: (p) {
          if (p == null) {
            return const Center(
              child: Text('Uzupełnij profil, aby zobaczyć wyliczenia'),
            );
          }
          final result = BmrCalculator.calculateFull(p);
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _row(
                      'BMR (spoczynkowe)',
                      '${result.bmr.toStringAsFixed(0)} kcal',
                    ),
                    _row(
                      'TDEE (całkowite)',
                      '${result.tdee.toStringAsFixed(0)} kcal',
                    ),
                    _row(
                      'Cel kaloryczny (${p.cel.label})',
                      '${result.celKalorii.toStringAsFixed(0)} kcal',
                    ),
                    const Divider(height: 32),
                    _row('Białko', '${result.bialkoG.toStringAsFixed(0)} g'),
                    _row('Tłuszcz', '${result.tluszczG.toStringAsFixed(0)} g'),
                    _row(
                      'Węglowodany',
                      '${result.weglowodanyG.toStringAsFixed(0)} g',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Błąd: $e')),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Semantics(
      label: label,
      value: value,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final texts = [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ];
          if (constraints.maxWidth < 480 ||
              MediaQuery.textScalerOf(context).scale(16) > 20) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: texts,
            );
          }
          return Row(
            children: [
              Expanded(child: texts[0]),
              const SizedBox(width: 16),
              texts[1],
            ],
          );
        },
      ),
    ),
  );
}
