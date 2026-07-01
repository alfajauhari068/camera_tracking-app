import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;

typedef AspectRatioChanged = void Function(String ratio);
typedef ZoomLevelChanged = void Function(double zoom);
typedef ModeChanged = void Function(String mode);

enum CameraPanel { none, theme, flash, grid, layers, settings }

class CameraView extends StatefulWidget {
  final CameraPanel activePanel;
  final String selectedMode; // e.g., 'photo', 'video', 'tracking'

  final Widget cameraPreview;
  final String selectedAspectRatio;
  final bool isFlashOn;
  final bool showGridLines;
  final double zoomLevel;
  final String locationName;
  final String addressLine;
  final String coordinates;
  final String accuracyLabel;
  final DateTime timestamp;
  final VoidCallback onFlashToggle;
  final VoidCallback onGridToggle;
  final VoidCallback onCapture;
  final AspectRatioChanged onAspectRatioChanged;
  final ZoomLevelChanged onZoomLevelChanged;

  /// Camera Mode selector callback
  final Function(String mode)? onModeChanged;

  /// Bottom Control callbacks
  final VoidCallback? onGalleryPressed;
  final VoidCallback? onSwitchCameraPressed;

  /// Top Actions Bar callbacks (optional to keep backwards compatibility)
  final VoidCallback? onWatermarkThemeCycle;
  final VoidCallback? onMockGpsToggle;
  final VoidCallback? onRotateCameraToggle;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onLayersPressed;

  /// Visual states for the toggle buttons
  final bool isMockGpsActive;
  final String watermarkTheme;

  const CameraView({
    super.key,
    required this.activePanel,
    required this.selectedMode,
    required this.cameraPreview,
    required this.selectedAspectRatio,
    required this.isFlashOn,
    required this.showGridLines,
    required this.zoomLevel,
    required this.locationName,
    required this.addressLine,
    required this.coordinates,
    required this.accuracyLabel,
    required this.timestamp,
    required this.onFlashToggle,
    required this.onGridToggle,
    required this.onCapture,
    required this.onAspectRatioChanged,
    required this.onZoomLevelChanged,

    this.onModeChanged,
    this.onGalleryPressed,
    this.onSwitchCameraPressed,
    this.onWatermarkThemeCycle,
    this.onMockGpsToggle,
    this.onRotateCameraToggle,
    this.onSettingsPressed,
    this.onLayersPressed,

    this.isMockGpsActive = false,
    this.watermarkTheme = 'Classic Navy',
  });

  static double calculateAspectRatio(String ratio) {
    final parts = ratio.split(':');
    if (parts.length != 2) return 16 / 9;

    final width = double.tryParse(parts[0]);
    final height = double.tryParse(parts[1]);
    if (width == null || height == null || height == 0) return 16 / 9;

    return width / height;
  }

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView>
    with SingleTickerProviderStateMixin {
  static const _aspectOptions = ['1:1', '3:4', '16:9', '9:16'];
  static const _zoomPresets = [0.6, 1.0, 2.0];

  bool _showFlashEffect = false;
  bool _showZoomControls = false;
  Timer? _zoomAutoHideTimer;

  void _triggerShutterFlash() {
    setState(() => _showFlashEffect = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _showFlashEffect = false);
    });
  }

  void _toggleZoomControls() {
    setState(() => _showZoomControls = !_showZoomControls);
    _zoomAutoHideTimer?.cancel();
    if (_showZoomControls) {
      _zoomAutoHideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showZoomControls = false);
      });
    }
  }

  void _onZoomChanged(double value) {
    widget.onZoomLevelChanged(value);
    _zoomAutoHideTimer?.cancel();
    _zoomAutoHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showZoomControls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratio = CameraView.calculateAspectRatio(widget.selectedAspectRatio);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 380 ? 8.0 : 16.0;

        return ClipRect(
          child: Stack(
            children: [
              // Layer 1: Full screen background (camera preview)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.cameraPreview,
                      if (widget.showGridLines) const _RuleOfThirdsGrid(),
                    ],
                  ),
                ),
              ),

              // Layer 2: Main layout overlay with proper hierarchy
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        // TOP BAR (8%)
                        _buildTopToolbar(),

                        // CAMERA PREVIEW AREA (70-75%) - occupied by background
                        Expanded(
                          flex: 70,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _buildCenterByActivePanel(),
                          ),
                        ),

                        // MODE SELECTOR (5%)
                        _buildModeSelector(),

                        // WATERMARK / LOCATION INFO (7%)
                        _buildBottomWatermark(Theme.of(context)),

                        // BOTTOM CONTROLS - Zoom, Zoom Slider, Aspect Ratio (8%)
                        SizedBox(
                          height: 140,
                          child: _buildControlsPanel(Theme.of(context)),
                        ),

                        // CAPTURE CONTROLS (10%)
                        _buildCaptureControls(Theme.of(context)),

                        // MODE SELECTOR (below capture controls)%n                        _buildModeSelector(),
                      ],
                    ),
                  ),
                ),
              ),

              // Flash overlay: ignore hit-test always.
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _showFlashEffect ? 0.75 : 0.0,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterByActivePanel() {
    final panel = widget.activePanel;
    if (panel == CameraPanel.none) return const SizedBox.shrink();

    // Placeholder card for now; prevents overlap & enforces single active panel.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _ActivePanelCard(panel: panel),
    );
  }

  Widget _buildTopToolbar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back
          _buildIconOnlyButton(
            icon: Icons.close,
            tooltip: 'Close',
            onTap: () => Navigator.of(context).maybePop(),
          ),

          const SizedBox(width: 10),

          // Middle toggles (theme/flash/grid/layers)
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                _buildToggleButton(
                  icon: Icons.water_drop,
                  label: 'Theme',
                  active:
                      widget.watermarkTheme.isNotEmpty &&
                      widget.activePanel == CameraPanel.theme,
                  onTap: () {
                    widget.onWatermarkThemeCycle?.call();
                  },
                ),
                _buildToggleButton(
                  icon: widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
                  label: 'Flash',
                  active: widget.activePanel == CameraPanel.flash,
                  onTap: () {
                    debugPrint('CLICK: FLASH');
                    widget.onFlashToggle();
                  },
                ),
                _buildToggleButton(
                  icon: Icons.grid_on,
                  label: 'Grid',
                  active: widget.activePanel == CameraPanel.grid,
                  onTap: () {
                    debugPrint('CLICK: GRID');
                    widget.onGridToggle();
                  },
                ),
                _buildToggleButton(
                  icon: Icons.layers,
                  label: 'Layers',
                  active: widget.activePanel == CameraPanel.layers,
                  onTap: () {
                    debugPrint('CLICK: LAYERS');
                    widget.onLayersPressed?.call();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Right toggles (settings/mock/rotate) - keep optional
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _buildIconOnlyButton(
                icon: Icons.my_location,
                tooltip: 'Mock GPS',
                active: widget.isMockGpsActive,
                onTap: widget.onMockGpsToggle ?? () {},
              ),
              _buildIconOnlyButton(
                icon: Icons.settings,
                tooltip: 'Settings',
                active: widget.activePanel == CameraPanel.settings,
                onTap: () {
                  debugPrint('CLICK: SETTINGS');
                  widget.onSettingsPressed?.call();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// MODE SELECTOR - Photo, Video, Tracking, Target, Detection (5% of screen)

  /// CONTROLS PANEL - Zoom and Aspect Ratio controls - Auto-hide
  Widget _buildControlsPanel(ThemeData theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _showZoomControls
          ? _buildControlsPanelExpanded(theme)
          : _buildControlsPanelCollapsed(theme),
    );
  }

  Widget _buildControlsPanelExpanded(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildZoomAndRatioBar(theme),
          const SizedBox(height: 8),
          _buildAspectRatioPills(theme),
        ],
      ),
    );
  }

  Widget _buildControlsPanelCollapsed(ThemeData theme) {
    return InkWell(
      onTap: _toggleZoomControls,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: Icon(Icons.unfold_more, color: Colors.white54, size: 28),
      ),
    );
  }

  Widget _buildModeSelector() {
    final modes = [
      ('Photo', 'photo'),
      ('Video', 'video'),
      ('Tracking', 'tracking'),
      ('Target', 'target'),
      ('Detection', 'detection'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: modes.map((entry) {
            final label = entry.$1;
            final modeValue = entry.$2;
            final isSelected = widget.selectedMode == modeValue;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    widget.onModeChanged?.call(modeValue);
                  },
                  splashColor: Colors.cyanAccent.withOpacity(0.3),
                  highlightColor: Colors.cyanAccent.withOpacity(0.1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent : Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent : Colors.white24,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.25),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// CAPTURE CONTROLS - Gallery, Shoot button, Switch Camera (10%)
  Widget _buildCaptureControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery button
          _buildCaptureControlButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: widget.onGalleryPressed ?? () {},
          ),

          // Capture button (centered, larger)
          _buildShutterButton(theme),

          // Switch camera button
          _buildCaptureControlButton(
            icon: Icons.flip_camera_ios,
            label: 'Switch',
            onTap: widget.onSwitchCameraPressed ?? () {},
          ),
        ],
      ),
    );
  }

  /// SHUTTER BUTTON - Main capture button
  Widget _buildShutterButton(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Shutter',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(56),
              onTap: () {
                debugPrint('BUTTON CLICKED: CAPTURE');
                _triggerShutterFlash();
                widget.onCapture();
              },
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Jepret',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// CAPTURE CONTROL BUTTON - Gallery or Switch Camera
  Widget _buildCaptureControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildZoomAndRatioBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zoom presets: fixed width
          SizedBox(width: 120, child: _buildZoomPresetBar(theme)),
          const SizedBox(width: 12),
          // Zoom slider: flexible with min width
          Expanded(child: _buildZoomSlider(theme)),
        ],
      ),
    );
  }

  Widget _buildZoomPresetBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Zoom',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Wrap(
          direction: Axis.vertical,
          alignment: WrapAlignment.center,
          spacing: 4,
          children: _zoomPresets.map((preset) {
            final isSelected =
                widget.zoomLevel.toStringAsFixed(1) ==
                preset.toStringAsFixed(1);
            return _buildSmallButton(
              label: preset == 0.6
                  ? 'WIDE'
                  : preset == 1.0
                  ? '1.0x'
                  : 'TELE',
              active: isSelected,
              onTap: () => widget.onZoomLevelChanged(preset),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildZoomSlider(ThemeData theme) {
    final clampedZoom = widget.zoomLevel.clamp(0.6, 2.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            'Zoom',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.amber,
            inactiveTrackColor: Colors.white38,
            thumbColor: Colors.amber,
            overlayColor: Colors.amber.withAlpha((0.24 * 255).round()),
            trackHeight: 4.0,
          ),
          child: Slider(
            value: clampedZoom,
            min: 0.6,
            max: 2.0,
            divisions: 28,
            label: '${clampedZoom.toStringAsFixed(1)}x',
            onChanged: _onZoomChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${clampedZoom.toStringAsFixed(1)}x',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildAspectRatioPills(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: _aspectOptions.map((ratio) {
          final isSelected = widget.selectedAspectRatio == ratio;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => widget.onAspectRatioChanged(ratio),
              splashColor: Colors.cyanAccent.withOpacity(0.3),
              highlightColor: Colors.cyanAccent.withOpacity(0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.cyanAccent : Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? Colors.cyanAccent : Colors.white24,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  ratio,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: Colors.amber.withOpacity(0.3),
        highlightColor: Colors.amber.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.amber : Colors.black54,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? Colors.amber : Colors.white24,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconOnlyButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(active ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? Colors.amber : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? Colors.amber : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: Colors.amber.withOpacity(0.3),
        highlightColor: Colors.amber.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? Colors.amber : Colors.white24,
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: active ? Colors.amber : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: active ? Colors.amber : Colors.white,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomWatermark(ThemeData theme) {
    final timeText = MaterialLocalizations.of(
      context,
    ).formatFullDate(widget.timestamp);
    final timeHour = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(widget.timestamp),
      alwaysUse24HourFormat: true,
    );

    final themeId = widget.watermarkTheme;

    late final Color panelBg;
    late final Color borderColor;
    late final TextStyle textStyle;

    switch (themeId) {
      case 'Classic Navy':
        panelBg = const Color(0xBB161D30);
        borderColor = const Color(0xFF39FF14);
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: const Color(0xFFFFFFFF),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        );
        break;
      case 'Pure OLED Black':
        panelBg = const Color(0xDD000000);
        borderColor = const Color(0xFF00E5FF);
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: const Color(0xFFFFFFFF),
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          fontSize: 13,
        );
        break;
      case 'Sunset Slate':
        panelBg = const Color(0xBB334155);
        borderColor = const Color(0xFFFF6D00);
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: const Color(0xFFFF6D00),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        );
        break;
      default:
        panelBg = const Color(0xBB161D30);
        borderColor = const Color(0xFF39FF14);
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: const Color(0xFFFFFFFF),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        );
    }

    final accentText = textStyle.color ?? const Color(0xFFFFFFFF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location and Accuracy Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.locationName,
                        style: textStyle.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: borderColor.withOpacity(0.7),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.accuracyLabel.replaceAll('±', '').trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accentText,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Address Line
                Text(
                  widget.addressLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Coordinates
                Text(
                  widget.coordinates,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Timestamp
                Text(
                  '$timeText · $timeHour',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivePanelCard extends StatelessWidget {
  final CameraPanel panel;

  const _ActivePanelCard({required this.panel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg = Colors.black.withOpacity(0.45);
    Color border = Colors.white.withOpacity(0.15);
    String title = 'Panel';

    switch (panel) {
      case CameraPanel.theme:
        title = 'Theme';
        bg = const Color(0xAA161D30);
        border = Colors.amber.withOpacity(0.35);
        break;
      case CameraPanel.flash:
        title = 'Flash';
        bg = Colors.black.withOpacity(0.55);
        border = Colors.amber.withOpacity(0.35);
        break;
      case CameraPanel.grid:
        title = 'Grid';
        bg = Colors.black.withOpacity(0.55);
        border = Colors.cyanAccent.withOpacity(0.35);
        break;
      case CameraPanel.layers:
        title = 'Layers';
        bg = Colors.black.withOpacity(0.55);
        border = Colors.purpleAccent.withOpacity(0.35);
        break;
      case CameraPanel.settings:
        title = 'Settings';
        bg = Colors.black.withOpacity(0.55);
        border = Colors.white.withOpacity(0.2);
        break;
      case CameraPanel.none:
        title = 'None';
        break;
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Panel aktif: ${panel.name}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleOfThirdsGrid extends StatelessWidget {
  const _RuleOfThirdsGrid();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RuleOfThirdsPainter(color: Colors.white54, strokeWidth: 1),
      ),
    );
  }
}

class _RuleOfThirdsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _RuleOfThirdsPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;

    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
