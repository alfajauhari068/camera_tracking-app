import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;


typedef AspectRatioChanged = void Function(String ratio);
typedef ZoomLevelChanged = void Function(double zoom);

class CameraView extends StatefulWidget {
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

  /// Top Actions Bar callbacks (optional to keep backwards compatibility)
  final VoidCallback? onWatermarkThemeCycle;
  final VoidCallback? onMockGpsToggle;
  final VoidCallback? onRotateCameraToggle;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onLayersPressed;

  /// Visual states for the toggle buttons
  final bool isMockGpsActive;
  final String watermarkTheme;

  final bool isLayersPanelActive;

  const CameraView({
    super.key,
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

    this.onWatermarkThemeCycle,
    this.onMockGpsToggle,
    this.onRotateCameraToggle,
    this.onSettingsPressed,
    this.onLayersPressed,

    this.isMockGpsActive = false,
    this.watermarkTheme = 'Classic Navy',
    this.isLayersPanelActive = false,
  });


  // NOTE: Constructor moved above to initialize all finals.


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

  void _triggerShutterFlash() {
    setState(() => _showFlashEffect = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _showFlashEffect = false);
    });
  }

  void _cycleAspectRatio() {
    final current = widget.selectedAspectRatio;
    final nextIndex = (_aspectOptions.indexWhere((value) => value == current) + 1) %
        _aspectOptions.length;
    widget.onAspectRatioChanged(_aspectOptions[nextIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = CameraView.calculateAspectRatio(widget.selectedAspectRatio);
    return ClipRect(
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: ratio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.cameraPreview,
                if (widget.showGridLines)
                  const _RuleOfThirdsGrid(),
              ],
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopOverlay(theme),
                    const Spacer(),
                    _buildZoomAndRatioBar(theme),
                    const SizedBox(height: 6),
                    _buildAspectRatioPills(theme),
                    const SizedBox(height: 12),
                    _buildBottomWatermark(theme),

                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _showFlashEffect ? 0.75 : 0.0,
              child: Container(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverlay(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconOnlyButton(
          icon: Icons.close,
          active: false,
          onTap: () => Navigator.of(context).maybePop(),
          tooltip: 'Close',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(
              icon: Icons.water_drop,
              label: 'Theme',
              active: widget.watermarkTheme.isNotEmpty,
              onTap: widget.onWatermarkThemeCycle ?? () {},
            ),
            const SizedBox(width: 10),

            _buildIconButton(
              icon: widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
              label: 'Flash',
              active: widget.isFlashOn,
              onTap: widget.onFlashToggle,
            ),
            const SizedBox(width: 10),
            _buildIconButton(
              icon: Icons.grid_on,
              label: 'Grid',
              active: widget.showGridLines,
              onTap: widget.onGridToggle,
            ),
            const SizedBox(width: 10),
            _buildIconButton(
              icon: Icons.layers,
              label: 'Layers',
              active: widget.isLayersPanelActive,
              onTap: widget.onLayersPressed ?? () {},
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildIconOnlyButton(
              icon: Icons.my_location,
              active: widget.isMockGpsActive,
              onTap: widget.onMockGpsToggle ?? () {},
              tooltip: 'Mock GPS',
            ),
            const SizedBox(width: 10),
            _buildIconOnlyButton(
              icon: Icons.rotate_right,
              active: false,
              onTap: widget.onRotateCameraToggle ?? () {},
              tooltip: 'Rotate camera',
            ),
            const SizedBox(width: 10),
            _buildIconOnlyButton(
              icon: Icons.settings,
              active: false,
              onTap: widget.onSettingsPressed ?? () {},
              tooltip: 'Settings',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconOnlyButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? Colors.amber : Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? Colors.amber : Colors.white,
          ),
        ),
      ),
    );
  }


  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? Colors.amber : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? Colors.amber : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectBadge(ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _cycleAspectRatio,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          widget.selectedAspectRatio,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildZoomAndRatioBar(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildZoomPresetBar(theme),
            _buildShutterControl(theme),
            _buildAspectRatioBar(theme),
          ],
        ),
        const SizedBox(height: 10),
        _buildZoomSlider(theme),
      ],
    );
  }

  Widget _buildZoomPresetBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zoom', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Row(
          children: _zoomPresets.map((preset) {
            final isSelected = widget.zoomLevel.toStringAsFixed(1) == preset.toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildSmallButton(
                label: preset == 0.6 ? 'WIDE' : preset == 1.0 ? '1.0x' : 'TELE',
                active: isSelected,
                onTap: () => widget.onZoomLevelChanged(preset),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAspectRatioBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Ratio', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Row(
          children: _aspectOptions.map((ratio) {
            final isSelected = widget.selectedAspectRatio == ratio;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildSmallButton(
                label: ratio,
                active: isSelected,
                onTap: () => widget.onAspectRatioChanged(ratio),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAspectRatioPills(ThemeData theme) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _aspectOptions.map((ratio) {
          final isSelected = widget.selectedAspectRatio == ratio;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                // HapticFeedback is available via flutter/services.dart in some setups;
                // fallback to no-op when not supported.
                // ignore: avoid_print
                // (No import changes here to prevent architecture violations.)
                // If haptics are desired, wire it at widget layer that already imports services.
                

                widget.onAspectRatioChanged(ratio);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.cyanAccent : Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? Colors.cyanAccent : Colors.white24,
                    width: 1,
                  ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.amber : Colors.black54,
          borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildZoomSlider(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.amber,
            inactiveTrackColor: Colors.white38,
            thumbColor: Colors.amber,
            overlayColor: Colors.amber.withAlpha((0.24 * 255).round()),
          ),
          child: Slider(
            value: widget.zoomLevel.clamp(0.6, 2.0),
            min: 0.6,
            max: 2.0,
            onChanged: widget.onZoomLevelChanged,
          ),
        ),
        Text(
          'Zoom ${widget.zoomLevel.toStringAsFixed(1)}x',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildShutterControl(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'Shutter',
            child: InkWell(
              borderRadius: BorderRadius.circular(56),
              onTap: () {
                _triggerShutterFlash();
                widget.onCapture();
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.25 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jepret',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomWatermark(ThemeData theme) {
    final timeText = MaterialLocalizations.of(context).formatFullDate(widget.timestamp);
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
        );
        break;
      case 'Pure OLED Black':
        panelBg = const Color(0xDD000000);
        borderColor = const Color(0xFF00E5FF);
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: const Color(0xFFFFFFFF),
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        );
        break;
      case 'Sunset Slate':
        panelBg = const Color(0xBB334155);
        borderColor = const Color(0xFFFF6D00);
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: const Color(0xFFFF6D00),
          fontWeight: FontWeight.w800,
        );
        break;
      default:
        panelBg = const Color(0xBB161D30);
        borderColor = const Color(0xFF39FF14);
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: const Color(0xFFFFFFFF),
          fontWeight: FontWeight.w800,
        );
    }

    final accentText = textStyle.color ?? const Color(0xFFFFFFFF);


    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.locationName,
                      style: textStyle,
                    ),

                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: borderColor.withOpacity(0.7), width: 1),
                    ),
                    child: Text(
                      widget.accuracyLabel.replaceAll('±', '').trim(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accentText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.addressLine,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.coordinates,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$timeText · $timeHour',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
        painter: _RuleOfThirdsPainter(
          color: Colors.white54,
          strokeWidth: 1,
        ),
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

    canvas.drawLine(Offset(thirdWidth, 0), Offset(thirdWidth, size.height), paint);
    canvas.drawLine(Offset(thirdWidth * 2, 0), Offset(thirdWidth * 2, size.height), paint);
    canvas.drawLine(Offset(0, thirdHeight), Offset(size.width, thirdHeight), paint);
    canvas.drawLine(Offset(0, thirdHeight * 2), Offset(size.width, thirdHeight * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
