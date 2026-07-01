import 'package:flutter/material.dart';

/// Abstract color palette contract for theme variants.
abstract class AppColors {
  Color get primary;
  Color get accent;
  Color get panelBg;
}

/// Classic Navy & Neon palette
class ClassicNavy implements AppColors {
  const ClassicNavy();
  static const ClassicNavy instance = ClassicNavy();

  @override
  Color get primary => const Color(0xFF0A0F1D);

  @override
  Color get accent => const Color(0xFF39FF14);

  @override
  Color get panelBg => const Color(0xFF161D30);
}

/// Pure OLED Black palette
class PureOled implements AppColors {
  const PureOled();
  static const PureOled instance = PureOled();

  @override
  Color get primary => const Color(0xFF000000);

  @override
  Color get accent => const Color(0xFF00E5FF);

  @override
  Color get panelBg => const Color(0xFF121212);
}

/// Slate & Sunset Orange palette
class SlateSunset implements AppColors {
  const SlateSunset();
  static const SlateSunset instance = SlateSunset();

  @override
  Color get primary => const Color(0xFF1E293B);

  @override
  Color get accent => const Color(0xFFFF6D00);

  @override
  Color get panelBg => const Color(0xFF334155);
}

/// Extension on ThemeData to access named palettes reactively via Theme.of(context)
extension ThemeDataExtension on ThemeData {
  AppColors get classicNavy => ClassicNavy.instance;
  AppColors get pureOled => PureOled.instance;
  AppColors get slateSunset => SlateSunset.instance;
}
