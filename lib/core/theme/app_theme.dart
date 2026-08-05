import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color voidBlack = Color(0xFF08090A);
  static const Color darkBackground = Color(0xFF0D0E10);
  static const Color darkCard = Color(0xFF171719);
  static const Color darkCardRaised = Color(0xFF211D1A);
  static const Color darkCardBorder = Color(0xFF4B3C2C);

  static const Color miningGreen = Color(0xFF879B70);
  static const Color miningGreenLight = Color(0xFFA7B982);

  static const Color smithingOrange = Color(0xFFC48749);
  static const Color smithingBrown = Color(0xFF684633);

  static const Color combatRed = Color(0xFFD16B63);
  static const Color combatBlue = Color(0xFF86A9B5);

  static const Color bronze = Color(0xFFA7793E);
  static const Color accentYellow = Color(0xFFD0A65B);
  static const Color textPrimary = Color(0xFFD8C9AA);
  static const Color textSecondary = Color(0xFF948A78);
  static const Color progressBar = Color(0xFFB98845);

  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(5));

  static ThemeData get theme {
    const colorScheme = ColorScheme.dark(
      primary: progressBar,
      onPrimary: voidBlack,
      secondary: accentYellow,
      onSecondary: voidBlack,
      surface: darkCard,
      onSurface: textPrimary,
      error: combatRed,
      outline: darkCardBorder,
      surfaceContainerHighest: darkCardRaised,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,
      primaryColor: progressBar,
      colorScheme: colorScheme,
      fontFamily: 'serif',
      splashColor: accentYellow.withValues(alpha: 0.1),
      highlightColor: accentYellow.withValues(alpha: 0.05),
      dividerColor: darkCardBorder,
      iconTheme: const IconThemeData(color: textSecondary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: progressBar,
        linearTrackColor: voidBlack,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12, height: 1.25),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14, height: 1.25),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        elevation: 4,
        shape: BeveledRectangleBorder(
          borderRadius: panelRadius,
          side: BorderSide(color: darkCardBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accentYellow,
        unselectedItemColor: textSecondary,
        selectedIconTheme: IconThemeData(size: 23),
        unselectedIconTheme: IconThemeData(size: 21),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bronze,
          foregroundColor: voidBlack,
          shape: const BeveledRectangleBorder(borderRadius: panelRadius),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: darkCardBorder),
          shape: const BeveledRectangleBorder(borderRadius: panelRadius),
        ),
      ),
    );
  }
}
