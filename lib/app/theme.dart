import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolory marki FitBirek - pomarańczowy akcent, grafitowe tło dark.
class FitBirekColors {
  static const Color accent = Color(0xFFFF6B35);
  static const Color darkBackground = Color(0xFF1A1D23);
  static const Color darkSurface = Color(0xFF23262E);
  static const Color darkSurfaceVariant = Color(0xFF2C2F38);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color danger = Color(0xFFE53935);
}

/// ThemeExtension z dodatkowymi kolorami specyficznymi dla domeny fitness
/// (kolory RPE, statusów PR itd.) - żeby nie zaśmiecać ColorScheme.
@immutable
class FitBirekThemeExtension extends ThemeExtension<FitBirekThemeExtension> {
  const FitBirekThemeExtension({
    required this.success,
    required this.warning,
    required this.danger,
    required this.cardBackground,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color cardBackground;

  @override
  FitBirekThemeExtension copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? cardBackground,
  }) {
    return FitBirekThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      cardBackground: cardBackground ?? this.cardBackground,
    );
  }

  @override
  FitBirekThemeExtension lerp(
      ThemeExtension<FitBirekThemeExtension>? other, double t) {
    if (other is! FitBirekThemeExtension) return this;
    return FitBirekThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
    );
  }
}

class FitBirekTheme {
  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FitBirekColors.accent,
        brightness: Brightness.dark,
        surface: FitBirekColors.darkSurface,
      ),
      scaffoldBackgroundColor: FitBirekColors.darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: FitBirekColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: FitBirekColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FitBirekColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: FitBirekColors.accent,
        unselectedLabelColor: Colors.grey,
        indicatorColor: FitBirekColors.accent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FitBirekColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FitBirekColors.accent,
          side: const BorderSide(color: FitBirekColors.accent, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: FitBirekColors.accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitBirekColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FitBirekColors.darkSurfaceVariant,
        selectedColor: FitBirekColors.accent,
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FitBirekColors.darkSurface,
        selectedItemColor: FitBirekColors.accent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: FitBirekColors.accent,
        thumbColor: FitBirekColors.accent,
        inactiveTrackColor: FitBirekColors.darkSurfaceVariant,
      ),
      extensions: const [
        FitBirekThemeExtension(
          success: FitBirekColors.success,
          warning: FitBirekColors.warning,
          danger: FitBirekColors.danger,
          cardBackground: FitBirekColors.darkSurface,
        ),
      ],
    );
  }

  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FitBirekColors.accent,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FitBirekColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      extensions: const [
        FitBirekThemeExtension(
          success: FitBirekColors.success,
          warning: FitBirekColors.warning,
          danger: FitBirekColors.danger,
          cardBackground: Colors.white,
        ),
      ],
    );
  }
}
