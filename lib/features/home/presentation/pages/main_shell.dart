import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

/// Główny shell aplikacji z BottomNavigationBar (5 zakładek).
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final Widget child;
  final int currentIndex;
  final void Function(int index) onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Dziś',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Baza',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Trening',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Postępy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ustawienia',
          ),
        ],
      ),
    );
  }
}

/// Kolor pomocniczy do accentowanych elementów w zakładkach.
class TabColors {
  static const active = FitBirekColors.accent;
}
