import 'package:flutter/material.dart';

/// Design tokens khusus UI kamera (overlay).
///
/// Tujuan:
/// - Mengangkat hardcoded color/spacing/radius dari widget kamera.
/// - Tetap ringan (tidak mengubah design system global).
class CameraColors {
  const CameraColors._();

  static Color overlayBackground(BuildContext context) =>
      Colors.black.withOpacity(0.55);

  static Color overlayBorder(BuildContext context) =>
      Colors.white.withOpacity(0.08);

  static Color overlayTextPrimary(BuildContext context) => Colors.white;

  static Color overlayTextSecondary(BuildContext context) =>
      Colors.white.withOpacity(0.75);

  static Color badgeRecording(BuildContext context) => Colors.red;
}

class CameraSpacing {
  const CameraSpacing._();

  static const double overlayPadding = 12;
  static const double gapSm = 6;
  static const double gapMd = 8;
  static const double gapLg = 10;
}

class CameraRadius {
  const CameraRadius._();

  static const double overlayCard = 12;
}

