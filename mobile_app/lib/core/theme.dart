import 'package:flutter/material.dart';

/// Central theme so the app doesn't accumulate ad-hoc colors/styles per
/// screen. Swap the seed color / typography here to reskin the whole app.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0B5FFF);
  static const Color secondary = Color(0xFF00B894);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, secondary: secondary),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
