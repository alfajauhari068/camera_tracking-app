import 'package:flutter/material.dart';

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
      children: [
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
        const Spacer(),
        _buildAspectBadge(theme),
      ],
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.locationName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.addressLine,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.coordinates,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
              Text(
                widget.accuracyLabel,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$timeText · $timeHour',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ],
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
