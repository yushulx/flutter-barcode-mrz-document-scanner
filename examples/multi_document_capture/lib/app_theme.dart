import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color dyOrange = Color(0xFFFE8E14);
  static const Color dyBlack2B = Color(0xFF2B2B2B);
  static const Color dyBlack34 = Color(0xFF323234);
  static const Color dyGray = Color(0xFF999999);
  static const Color semiTransparentBlack = Color(0x88000000);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dyBlack2B,
      colorScheme: const ColorScheme.dark(
        primary: dyOrange,
        onPrimary: Colors.white,
        surface: dyBlack2B,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: dyBlack2B,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
