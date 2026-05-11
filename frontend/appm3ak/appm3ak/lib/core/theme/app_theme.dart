import 'package:flutter/material.dart';

/// Thème Ma3ak : palette bleu/violet premium + accessibilité.
class AppTheme {
  AppTheme._();

  static const Color _brandPrimary = Color(0xFF3D73FF);
  static const Color _brandSecondary = Color(0xFF6D43EA);
  static const Color _brandAccent = Color(0xFFC14AF6);
  static const Color _brandDarkBg = Color(0xFF2E2A3D);
  static const Color _brandDarkSurface = Color(0xFF3A3550);
  static const Color _brandDarkSurfaceSoft = Color(0xFF4C4A72);
  static const Color _brandLightBg = Color(0xFFF3F2FF);
  static const Color _brandLightSurface = Color(0xFFFFFFFF);
  static const Color _error = Color(0xFFCF3A63);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: _brandPrimary,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD8DCFF),
          onPrimaryContainer: Color(0xFF25214A),
          secondary: _brandSecondary,
          onSecondary: Colors.white,
          tertiary: _brandAccent,
          surface: _brandLightSurface,
          onSurface: Color(0xFF211D34),
          onSurfaceVariant: Color(0xFF575173),
          error: _error,
          onError: Colors.white,
          outline: Color(0xFF9E97C1),
        ),
        scaffoldBackgroundColor: _brandLightBg,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: _brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 52),
            backgroundColor: _brandPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 52),
            backgroundColor: _brandPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(88, 52),
            foregroundColor: const Color(0xFF2C2850),
            side: const BorderSide(color: Color(0xFF9E97C1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          color: _brandLightSurface,
          shadowColor: const Color(0x22000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE5E2FF),
          selectedColor: const Color(0xFFCFC8FF),
          labelStyle: const TextStyle(
            color: Color(0xFF2C2850),
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F6FF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3ADD2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3ADD2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _error),
          ),
          labelStyle: const TextStyle(fontSize: 16),
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF6F6895)),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF211D34),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF211D34),
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF211D34)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF211D34)),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        fontFamily: 'Roboto',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _brandPrimary,
          onPrimary: Colors.white,
          primaryContainer: _brandSecondary,
          onPrimaryContainer: Colors.white,
          secondary: _brandAccent,
          onSecondary: Colors.white,
          tertiary: Color(0xFF45A3FF),
          surface: _brandDarkSurface,
          onSurface: Colors.white,
          surfaceContainerHighest: _brandDarkSurfaceSoft,
          onSurfaceVariant: Color(0xFFD2CCF5),
          error: _error,
          onError: Colors.white,
          outline: Color(0xFF9D95C8),
        ),
        scaffoldBackgroundColor: _brandDarkBg,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: _brandDarkSurface,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 52),
            backgroundColor: _brandPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 52),
            backgroundColor: _brandPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(88, 52),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF9D95C8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          color: _brandDarkSurface,
          shadowColor: const Color(0x66000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF4C4A72),
          selectedColor: const Color(0xFF5A5784),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _brandDarkSurfaceSoft,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF9D95C8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF9D95C8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brandPrimary, width: 2),
          ),
          labelStyle: const TextStyle(fontSize: 16, color: Colors.white),
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFFD2CCF5)),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        fontFamily: 'Roboto',
      );
}
