import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/primary_button.dart';

/// Ekran 1 onboardingu: powitanie + nazwa aplikacji.
class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: FitBirekColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: FitBirekColors.accent,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              Text(
                'FitBirek',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 12),
              Text(
                'Twój osobisty asystent treningowy',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Baza ćwiczeń, dziennik treningowy, postępy\ni plany dopasowane do treningu w domu',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              const Spacer(flex: 3),
              PrimaryButton(
                label: 'Zaczynajmy',
                icon: Icons.arrow_forward,
                onPressed: onNext,
              ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
