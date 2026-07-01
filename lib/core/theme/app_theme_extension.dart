import 'package:flutter/material.dart';

/// Minimal theme extension point untuk tokens design system.
///
/// Saat ini proyek sudah memakai [ThemeData] + [ColorScheme].
/// File ini disiapkan agar ke depan token UI bisa diambil lewat
/// `Theme.of(context).extension<...>()` tanpa hardcode.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color overlayPanelColor;
  final Color overlayBorderColor;
  final Color overlayBackgroundColor;

  final Color iconButtonBackground;
  final Color iconButtonIconColor;

  final double radiusXs;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  const AppThemeExtension({
    required this.overlayPanelColor,
    required this.overlayBorderColor,
    required this.overlayBackgroundColor,
    required this.iconButtonBackground,
    required this.iconButtonIconColor,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
  });

  @override
  AppThemeExtension copyWith({
    Color? overlayPanelColor,
    Color? overlayBorderColor,
    Color? overlayBackgroundColor,
    Color? iconButtonBackground,
    Color? iconButtonIconColor,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
  }) {
    return AppThemeExtension(
      overlayPanelColor: overlayPanelColor ?? this.overlayPanelColor,
      overlayBorderColor: overlayBorderColor ?? this.overlayBorderColor,
      overlayBackgroundColor: overlayBackgroundColor ?? this.overlayBackgroundColor,
      iconButtonBackground: iconButtonBackground ?? this.iconButtonBackground,
      iconButtonIconColor: iconButtonIconColor ?? this.iconButtonIconColor,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
    );
  }

  @override
  AppThemeExtension lerp(
    covariant AppThemeExtension? other,
    double t,
  ) {
    if (other == null) return this;

    return AppThemeExtension(
      overlayPanelColor: Color.lerp(overlayPanelColor, other.overlayPanelColor, t)!,
      overlayBorderColor: Color.lerp(overlayBorderColor, other.overlayBorderColor, t)!,
      overlayBackgroundColor:
          Color.lerp(overlayBackgroundColor, other.overlayBackgroundColor, t)!,
      iconButtonBackground: Color.lerp(iconButtonBackground, other.iconButtonBackground, t)!,
      iconButtonIconColor: Color.lerp(iconButtonIconColor, other.iconButtonIconColor, t)!,
      radiusXs: _lerpDouble(radiusXs, other.radiusXs, t),
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
      radiusXl: _lerpDouble(radiusXl, other.radiusXl, t),

    );
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}


