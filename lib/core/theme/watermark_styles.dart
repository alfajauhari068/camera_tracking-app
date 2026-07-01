import 'dart:ui';

import 'package:flutter/material.dart';
import 'app_colors.dart';

class WatermarkStyles {
  /// Default font size for watermark metadata
  static const double defaultFontSize = 12.0;

  /// Returns a readable TextStyle adapted to the given palette and size.
  static TextStyle textStyle(AppColors palette, {double? fontSize}) {
    return TextStyle(
      color: palette.accent,
      fontSize: fontSize ?? defaultFontSize,
      fontWeight: FontWeight.w500,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.6),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    );
  }

  /// Builds a watermark panel container with a backdrop blur and semi-transparent background.
  /// Usage: wrap overlay content with this widget to ensure contrast on varied backgrounds.
  static Widget buildWatermarkPanel({
    required Widget child,
    required AppColors palette,
    double opacity = 0.6,
    double borderRadius = 8.0,
    EdgeInsets padding = const EdgeInsets.all(8.0),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Container(
          padding: padding,
          color: palette.panelBg.withOpacity(opacity),
          child: child,
        ),
      ),
    );
  }
}
