import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes.dart' as app_routes;
import '../../domain/entities/camera_tracking_state.dart';

/// =============================================================================
/// CAMERA TRACKING PAGE
/// =============================================================================
/// 
/// Layout:
/// - Full camera preview (background)
/// - Overlay: Coordinates, GPS status, current time (top)
/// - Bottom panel: Start/Stop, shutter, icon buttons
/// 
/// Theme: Dark, camera-focused
/// - Blue/grey overlay panels
/// - Green accent for "Tracking ON / GPS OK"
/// 
/// Route: /camera
class CameraTrackingPage extends ConsumerStatefulWidget {
  const CameraTrackingPage({super.key});

  @override
  ConsumerState<CameraTrackingPage> createState() => _CameraTrackingPageState();
}

class _CameraTrackingPageState extends ConsumerState<CameraTrackingPage> {
  Timer? _timer;
  
  // Dummy state - replace with real providers in production
  late CameraTrackingState _state;
  
  @override
  void initState() {
    super.initState();
    _state = CameraTrackingState.initial();
    _startTimer();
  }

  void _startTimer() {
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(currentTime: DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================================
      // BODY - Stack: Camera preview (back) + Overlay (front)
      // ========================================================================
      body: Stack(
        children: [
          // 1. Camera Preview (Full screen background)
          _buildCameraPreview(),
          
          // 2. Top Overlay - GPS info + Time
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(),
          ),
          
          // 3. Bottom Panel - Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CAMERA PREVIEW - Full screen background
  // =========================================================================
  
  Widget _buildCameraPreview() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Camera Preview\n(Pasang camera package)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  // =========================================================================
  // TOP OVERLAY - Coordinates + GPS Status + Time
  // =========================================================================
  
  Widget _buildTopOverlay() {
    final gps = _state.gpsInfo;
    final isGpsOk = gps.isEnabled && gps.hasLock;
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Row 1: Koordinat (kiri) + Waktu (kanan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Koordinat
              _InfoChip(
                icon: Icons.location_on,
                label: 'Koordinat',
                value: gps.coordinatesDisplay,
              ),
              // Waktu
              _TimeDisplay(time: _state.currentTime),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Row 2: GPS Status
          _GpsStatusIndicator(
            statusText: gps.statusText,
            isOk: isGpsOk,
            accuracy: gps.accuracyDisplay,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BOTTOM PANEL - Start/Stop + Shutter + Icons
  // =========================================================================
  
  Widget _buildBottomPanel() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Start/Stop Tracking Button (Besar)
          _TrackingButton(
            isActive: _state.isTrackingActive,
            onPressed: _toggleTracking,
          ),
          
          const SizedBox(height: 20),
          
          // Row 2: Action Icons + Shutter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Switch Camera
              _ActionIconButton(
                icon: Icons.flip_camera_android,
                label: 'Kamera',
                onPressed: _switchCamera,
              ),
              
              // Shutter (napshot)
              _ShutterButton(
                onPressed: _takeSnapshot,
              ),
              
              // Flash
              _ActionIconButton(
                icon: _state.isFlashOn ? Icons.flash_on : Icons.flash_off,
                label: 'Flash',
                isActive: _state.isFlashOn,
                onPressed: _toggleFlash,
              ),
              
              // Settings
              _ActionIconButton(
                icon: Icons.settings,
                label: 'Settings',
                onPressed: _openSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ACTIONS
  // =========================================================================
  
  void _toggleTracking() {
    setState(() {
      _state = _state.copyWith(
        isTrackingActive: !_state.isTrackingActive,
      );
    });
    
    // Show feedback
    final msg = _state.isTrackingActive 
        ? 'Tracking Dimulai' 
        : 'Tracking Dihentikan';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _switchCamera() {
    setState(() {
      _state = _state.copyWith(
        isFrontCamera: !_state.isFrontCamera,
      );
    });
  }

  void _toggleFlash() {
    setState(() {
      _state = _state.copyWith(
        isFlashOn: !_state.isFlashOn,
      );
    });
  }

  void _takeSnapshot() {
    // TODO: Implement snapshot
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Snapshot (placeholder)'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openSettings() {
    app_routes.navigateTo(context, app_routes.AppRoutes.settings);
  }
}

// =============================================================================
// INFO CHIP - Koordinat display
// =============================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1a237e).withOpacity(0.8), // Navy
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TIME DISPLAY - Current time
// =============================================================================

class _TimeDisplay extends StatelessWidget {
  final DateTime time;

  const _TimeDisplay({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e).withOpacity(0.8), // Dark grey
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(time),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatDate(time),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d/$mo/$y';
  }
}

// =============================================================================
// GPS STATUS INDICATOR
// =============================================================================

class _GpsStatusIndicator extends StatelessWidget {
  final String statusText;
  final bool isOk;
  final String accuracy;

  const _GpsStatusIndicator({
    required this.statusText,
    required this.isOk,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isOk 
        ? const Color(0xFF00e676)  // Neon green
        : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // GPS Icon
          Icon(
            isOk ? Icons.gps_fixed : Icons.gps_off,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          // Status text
          Text(
            'GPS: $statusText',
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isOk) ...[
            const SizedBox(width: 8),
            // Accuracy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                accuracy,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// TRACKING BUTTON - Start/Stop large button
// =============================================================================

class _TrackingButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _TrackingButton({
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isActive 
        ? const Color(0xFF00e676)  // Neon green
        : const Color(0xFF424242);  // Dark grey
    
    final Color textColor = isActive 
        ? Colors.black 
        : Colors.white;
    
    return SizedBox(
      width: double.infinity,
      height: 56, // Large, thumb-friendly
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isActive ? 4 : 0,
          shadowColor: isActive 
              ? const Color(0xFF00e676).withOpacity(0.5) 
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.stop : Icons.play_arrow,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'Stop Tracking' : 'Start Tracking',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHUTTER BUTTON - Snapshot
// =============================================================================

class _ShutterButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ShutterButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF1a237e), // Navy
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ACTION ICON BUTTON
// =============================================================================

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive 
        ? const Color(0xFF00e676)  // Neon green
        : Colors.white70;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 28, // Large touch target
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
