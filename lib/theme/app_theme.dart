import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF12B886); // verde Bio-G (acento)

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      ),
    );
  }
}
