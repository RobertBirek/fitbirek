import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import 'onboarding_welcome_page.dart';
import 'onboarding_profile_page.dart';
import 'onboarding_equipment_page.dart';

/// Kontroler przepływu onboardingu - 3 ekrany w PageView.
class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Dane zbierane w kroku 2, wykorzystywane przy zapisie w kroku 3.
  int _wiek = 47;
  double _wzrost = 180;
  double _waga = 94;
  CelTreningowy _cel = CelTreningowy.mix;
  List<String> _sprzet = const ['Masa własna'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish(List<String> sprzet) async {
    _sprzet = sprzet;
    final repo = ref.read(userProfileRepositoryProvider);
    await repo.saveProfile(
      imie: 'Robert',
      wiek: _wiek,
      wzrostCm: _wzrost,
      wagaKg: _waga,
      cel: _cel,
      dostepnySprzet: _sprzet,
      onboardingZakonczony: true,
    );
    // Router zareaguje automatycznie na zmianę stanu profilu (redirect w GoRouter).
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                OnboardingWelcomePage(onNext: () => _goToPage(1)),
                OnboardingProfilePage(
                  onNext: () => _goToPage(2),
                  onBack: () => _goToPage(0),
                  initialWiek: _wiek,
                  initialWzrost: _wzrost,
                  initialWaga: _waga,
                  initialCel: _cel,
                  onDataChanged: (wiek, wzrost, waga, cel) {
                    _wiek = wiek;
                    _wzrost = wzrost;
                    _waga = waga;
                    _cel = cel;
                  },
                ),
                OnboardingEquipmentPage(
                  onFinish: _finish,
                  onBack: () => _goToPage(1),
                  initialSelection: _sprzet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          children: List.generate(3, (index) {
            final active = index <= _currentPage;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
