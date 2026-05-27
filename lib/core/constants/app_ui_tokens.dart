import 'package:flutter/material.dart';

/// Centralized UI tokens for consistent layout + styling.
///
/// Design goals:
/// - Keep colors/radii/spacing in one place.
/// - Derive from [ThemeData] when possible.
/// - Avoid hardcoded styling spread across feature pages.
class AppUiTokens {
  const AppUiTokens._();

  // Base radii
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // Spacing scale
  static const double space1 = 4;
  static const double space2 = 6;
  static const double space3 = 8;
  static const double space4 = 10;
  static const double space5 = 12;
  static const double space6 = 16;
  static const double space7 = 20;
  static const double space8 = 24;

  static const double topBarHeight = 56;
  static const double bottomBarHeight = 70;
  static const double bottomModeHeight = 64;

  // Camera overlay tokens
  static Color overlayPanelColor(BuildContext context) =>
      Colors.black.withOpacity(0.4);

  static Color overlayPanelBorder(BuildContext context) =>
      Colors.white.withOpacity(0.08);

  static Color overlayPanelBackground(BuildContext context) =>
      Colors.black.withOpacity(0.55);

  static Color iconButtonBackground(BuildContext context) =>
      Colors.white.withOpacity(0.08);

  static Color iconButtonIconColor(BuildContext context) =>
      Colors.white;

  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

  static TextStyle titleBold(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700);

  static TextStyle labelSmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondaryColor(context)) ??
      TextStyle(color: textSecondaryColor(context));

  static TextStyle cameraMetaTitle(BuildContext context) =>
      const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700);

  static TextStyle cameraMetaTimestamp(BuildContext context) =>
      const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600);

  static TextStyle cameraMetaAddress(BuildContext context) =>
      TextStyle(
        color: Colors.white.withOpacity(0.75),
        fontSize: 12.5,
        height: 1.25,
      );

  static TextStyle cameraMetaCoords(BuildContext context) =>
      TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12);
}

