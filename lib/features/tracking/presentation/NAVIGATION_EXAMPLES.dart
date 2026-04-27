/// NAVIGATION EXAMPLES
/// 
/// File ini menunjukkan contoh-contoh concrete bagaimana menggunakan Navigator.pushNamed
/// di berbagai konteks widget (buttons, tiles, etc.)

// =============================================================================
// EXAMPLE 1: Simple Navigation dari Button (HomePage ke Gallery)
// =============================================================================

import 'package:flutter/material.dart';
import '../../../routes.dart' as app_routes;
import '../domain/entities/tracking.dart';

class SimpleNavigationExample extends StatelessWidget {
  const SimpleNavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =====================================================================
        // EXAMPLE 1: Navigate tanpa arguments
        // =====================================================================
        ElevatedButton(
          onPressed: () => _navigateToGallery(context),
          child: const Text('Go to Gallery'),
        ),

        const SizedBox(height: 12),

        // =====================================================================
        // EXAMPLE 2: Navigate dengan pass String ID
        // =====================================================================
        ElevatedButton(
          onPressed: () => _navigateToDetailWithId(context, 'tracking_id_123'),
          child: const Text('View Detail (with ID)'),
        ),

        const SizedBox(height: 12),

        // =====================================================================
        // EXAMPLE 3: Navigate dengan pass object
        // =====================================================================
        ElevatedButton(
          onPressed: () => _navigateToDetailWithObject(context),
          child: const Text('View Detail (with Object)'),
        ),

        const SizedBox(height: 12),

        // =====================================================================
        // EXAMPLE 4: Navigate to Map dengan highlight tracking
        // =====================================================================
        ElevatedButton(
          onPressed: () => _navigateToMapWithTracking(context),
          child: const Text('View on Map'),
        ),
      ],
    );
  }

  // =========================================================================
  // NAVIGATION METHODS - CONTOH IMPLEMENTASI
  // =========================================================================

  /// EXAMPLE 1: Navigate ke Gallery tanpa arguments
  void _navigateToGallery(BuildContext context) {
    // Method 1: Menggunakan Navigator.pushNamed() langsung
    Navigator.pushNamed(context, app_routes.AppRoutes.gallery);

    // Method 2: Menggunakan helper function dari routes.dart
    // app_routes.navigateTo(context, app_routes.AppRoutes.gallery);
  }

  /// EXAMPLE 2: Navigate ke Detail dengan pass String ID
  void _navigateToDetailWithId(BuildContext context, String trackingId) {
    // Method 1: Passing arguments
    Navigator.pushNamed(
      context,
      app_routes.AppRoutes.detail,
      arguments: trackingId,
    );

    // Method 2: Menggunakan helper function
    // app_routes.navigateTo(
    //   context,
    //   app_routes.AppRoutes.detail,
    //   arguments: trackingId,
    // );
  }

  /// EXAMPLE 3: Navigate ke Detail dengan pass Tracking object
  void _navigateToDetailWithObject(BuildContext context) {
    // Buat mock Tracking object
    final mockTracking = Tracking(
      id: 'tracking_001',
      imagePath: '/storage/emulated/0/Pictures/photo_001.jpg',
      latitude: -6.2088,
      longitude: 106.8456,
      address: 'Jakarta, Indonesia',
      accuracy: 5.5,
      timestamp: DateTime.now(),
    );

    // Pass ke Detail page
    Navigator.pushNamed(
      context,
      app_routes.AppRoutes.detail,
      arguments: mockTracking,
    );
  }

  /// EXAMPLE 4: Navigate ke Map dengan highlight satu tracking
  void _navigateToMapWithTracking(BuildContext context) {
    final mockTracking = Tracking(
      id: 'tracking_001',
      imagePath: '/storage/emulated/0/Pictures/photo_001.jpg',
      latitude: -6.2088,
      longitude: 106.8456,
      address: 'Jakarta, Indonesia',
      accuracy: 5.5,
      timestamp: DateTime.now(),
    );

    Navigator.pushNamed(
      context,
      app_routes.AppRoutes.map,
      arguments: mockTracking,
    );
  }
}

// =============================================================================
// EXAMPLE 5: ListTile dengan onTap Navigation
// =============================================================================

class PhotoListTileExample extends StatelessWidget {
  final String photoId;
  final String thumbnail;
  final String address;

  const PhotoListTileExample({
    super.key,
    required this.photoId,
    required this.thumbnail,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset(thumbnail),
      title: Text('Photo $photoId'),
      subtitle: Text(address),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        // Navigate ke detail page dengan pass photo ID
        Navigator.pushNamed(
          context,
          app_routes.AppRoutes.detail,
          arguments: photoId,
        );
      },
    );
  }
}

// =============================================================================
// EXAMPLE 6: GestureDetector dengan Navigation
// =============================================================================

class PhotoCardExample extends StatelessWidget {
  final String photoId;
  final Tracking tracking;

  const PhotoCardExample({
    super.key,
    required this.photoId,
    required this.tracking,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap foto → navigate ke detail
        Navigator.pushNamed(
          context,
          app_routes.AppRoutes.detail,
          arguments: tracking,
        );
      },
      child: Card(
        child: Column(
          children: [
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.image),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(tracking.address),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 7: Multi-step Navigation (Pop current + Push new)
// =====================================================================

class ReplaceNavigationExample extends StatelessWidget {
  const ReplaceNavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =====================================================================
        // Use Case: Setelah sukses capture, navigate ke gallery (replace camera screen)
        // =====================================================================
        ElevatedButton(
          onPressed: () => _navigateToCameraAndReplaceOnSuccess(context),
          child: const Text('Take Photo (Replace after success)'),
        ),

        const SizedBox(height: 12),

        // =====================================================================
        // Use Case: Navigate back to home (pop sampai home)
        // =====================================================================
        ElevatedButton(
          onPressed: () => _navigateBackToHome(context),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }

  /// Navigate ke camera, dan setelah sukses capture, replace dengan gallery
  /// (bukan push, jadi tidak bisa back ke camera)
  void _navigateToCameraAndReplaceOnSuccess(BuildContext context) {
    // Step 1: Push camera screen
    Navigator.pushNamed(context, app_routes.AppRoutes.camera);

    // Step 2: Di dalam CaptureScreen, setelah sukses capture:
    // Navigator.pushReplacementNamed(context, AppRoutes.gallery);
    // ^ Ini akan replace camera screen dengan gallery screen di stack
    // Jadi kalau user back, tidak akan kembali ke camera
  }

  /// Navigate back sampai home
  void _navigateBackToHome(BuildContext context) {
    // Pop sampai kita reach route dengan name '/'
    Navigator.popUntil(
      context,
      ModalRoute.withName(app_routes.AppRoutes.home),
    );

    // Atau alternatif: pop multiple times
    // Navigator.pop(context);
    // Navigator.pop(context);
    // Navigator.pop(context);
  }
}

// =============================================================================
// EXAMPLE 8: Passing & Receiving Arguments Pattern
// =============================================================================

/// Pattern untuk pass data ke detail page dan menerima hasilnya
class PassReceiveArgumentsExample extends StatelessWidget {
  const PassReceiveArgumentsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigateAndReceiveResult(context),
      child: const Text('Navigate & Get Result'),
    );
  }

  /// Navigate ke detail page dan tunggu result
  Future<void> _navigateAndReceiveResult(BuildContext context) async {
    // Push named route dan tunggu result
    final result = await Navigator.pushNamed<String>(
      context,
      app_routes.AppRoutes.detail,
      arguments: 'tracking_id_123',
    );

    // Setelah detail page di-pop, terima result di sini
    if (result != null) {
      print('Result from detail page: $result');
      // TODO: Update UI dengan result
    }
  }
}

// =============================================================================
// SUMMARY: PATTERN-PATTERN YANG UMUM DIGUNAKAN
// =============================================================================

/*

1. SIMPLE PUSH (Buka halaman baru)
   ```
   Navigator.pushNamed(context, AppRoutes.gallery);
   ```

2. PUSH DENGAN ARGUMENTS (Pass data)
   ```
   Navigator.pushNamed(
     context,
     AppRoutes.detail,
     arguments: trackingObject,
   );
   ```

3. PUSH REPLACEMENT (Replace screen, tidak bisa back)
   ```
   Navigator.pushReplacementNamed(context, AppRoutes.gallery);
   ```

4. POP SAMPAI ROUTE (Pop multiple screens sekaligus)
   ```
   Navigator.popUntil(context, ModalRoute.withName(AppRoutes.home));
   ```

5. PUSH & WAIT RESULT (Open screen dan tunggu result)
   ```
   final result = await Navigator.pushNamed<String>(
     context,
     AppRoutes.detail,
   );
   ```

6. HELPER FUNCTIONS (Dari routes.dart)
   ```
   navigateTo(context, AppRoutes.gallery);
   replaceWith(context, AppRoutes.home);
   popUntilRoute(context, AppRoutes.home);
   ```

*/
