import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class GC {
  static const bgDeep = Color(0xFF0D0627);
  static const bgCard = Color(0xFF1C0E4A);
  static const bgElevated = Color(0xFF2A1565);
  static const purple = Color(0xFF7B3FC8);
  static const purpleLight = Color(0xFF9B6FE8);
  static const gold = Color(0xFFF0C040);
  static const goldLight = Color(0xFFFFE082);
  static const pink = Color(0xFFFF6EB4);
  static const textMuted = Color(0xFFB0A0D0);
  static const deepPurple = Color(0xFF1A0050);
}

// Fredoka — display/logo/badges (fofo e arredondado)
TextStyle gfDisplay(double size, {FontWeight w = FontWeight.w700, Color c = Colors.white}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: w, color: c);

// Nunito — corpo/legendas (legível e suave)
TextStyle gfBody(double size, {FontWeight w = FontWeight.w500, Color c = Colors.white}) =>
    GoogleFonts.nunito(fontSize: size, fontWeight: w, color: c);

ThemeData gatodexTheme() {
  final base = ThemeData.dark();
  final nunitoText = GoogleFonts.nunitoTextTheme(
    base.textTheme,
  ).apply(bodyColor: Colors.white, displayColor: Colors.white);
  return base.copyWith(
    scaffoldBackgroundColor: GC.bgDeep,
    textTheme: nunitoText,
    colorScheme: const ColorScheme.dark(primary: GC.purple, secondary: GC.gold, surface: GC.bgCard),
    appBarTheme: AppBarTheme(backgroundColor: GC.bgDeep, elevation: 0, surfaceTintColor: Colors.transparent),
    dialogTheme: const DialogThemeData(backgroundColor: GC.bgCard),
  );
}
