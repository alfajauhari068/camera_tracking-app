import 'package:flutter/material.dart';

import '../../../../routes.dart' as app_routes;

/// HOME PAGE (Dashboard)
/// 
/// Tujuan: Menampilkan ringkasan dan navigasi cepat ke fitur utama
/// Route: /
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera GPS Tracking'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================================================================
            // WELCOME SECTION
            // ===================================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Camera Tracking',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track locations with photos and GPS coordinates',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Ringkasan stats (placeholder)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCard(label: 'Photos', value: '0'),
                        _StatCard(label: 'Locations', value: '0'),
                        _StatCard(label: 'Last Updated', value: '--'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===================================================================
            // MAIN ACTION BUTTONS (Grid 2x2)
            // ===================================================================
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                // Button 1: Take Photo
                _ActionButton(
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  onPressed: () => _navigateToCamera(context),
                ),

                // Button 2: Gallery
                _ActionButton(
                  icon: Icons.image,
                  label: 'Gallery',
                  onPressed: () => _navigateToGallery(context),
                ),

                // Button 3: Map
                _ActionButton(
                  icon: Icons.map,
                  label: 'Map View',
                  onPressed: () => _navigateToMap(context),
                ),

                // Button 4: Export
                _ActionButton(
                  icon: Icons.download,
                  label: 'Export Data',
                  onPressed: () => _navigateToExport(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // NAVIGATION METHODS - Contoh menggunakan Navigator.pushNamed
  // =========================================================================

  /// Navigate ke Camera screen
  void _navigateToCamera(BuildContext context) {
    app_routes.navigateTo(context, app_routes.AppRoutes.camera);
  }

  /// Navigate ke Gallery screen
  void _navigateToGallery(BuildContext context) {
    app_routes.navigateTo(context, app_routes.AppRoutes.gallery);
  }

  /// Navigate ke Map screen
  void _navigateToMap(BuildContext context) {
    app_routes.navigateTo(context, app_routes.AppRoutes.map);
  }

  /// Navigate ke Export screen
  void _navigateToExport(BuildContext context) {
    app_routes.navigateTo(context, app_routes.AppRoutes.export);
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

/// Stat card untuk menampilkan ringkasan data
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// Action button dengan icon dan label
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
