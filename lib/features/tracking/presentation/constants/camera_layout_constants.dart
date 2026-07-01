import 'package:flutter/material.dart';

/// Camera layout constants.
/// Per AI Rules: 07-ui-modernization.md (8pt grid), 08-ux-improvement.md
class CameraLayoutConstants {
  // Top bar
  static const double topBarHeight = 56.0;

  // Bottom controls
  static const double bottomControlsHeight = 120.0;


  // Capture button - 72px per 08-ux-improvement.md (outdoor visibility)
  static const double captureButtonSize = 72.0;
  static const double sideButtonSize = 48.0;


  // Spacing - 8pt grid per 07-ui-modernization.md
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;


  // Overlays
  static const double overlayMargin = 16.0;
  static const double gpsOverlayMaxWidth = 200.0;

  // Touch targets - WCAG per 07-ui-modernization.md
  static const double minTouchTarget = 48.0;
}

/// Camera mode enum.
enum CameraMode { photo, video, tracking, aiDetect }

