import 'package:flutter/material.dart';

abstract class GC {
  static const bgDeep     = Color(0xFF0D0627);
  static const bgCard     = Color(0xFF1C0E4A);
  static const bgElevated = Color(0xFF2A1565);
  static const purple     = Color(0xFF7B3FC8);
  static const purpleLight = Color(0xFF9B6FE8);
  static const gold       = Color(0xFFF0C040);
  static const goldLight  = Color(0xFFFFE082);
  static const pink       = Color(0xFFFF6EB4);
  static const textMuted  = Color(0xFFB0A0D0);
}

ThemeData gatodexTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: GC.bgDeep,
    colorScheme: const ColorScheme.dark(
      primary: GC.purple,
      secondary: GC.gold,
      surface: GC.bgCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GC.bgDeep,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: GC.bgCard),
  );
}
