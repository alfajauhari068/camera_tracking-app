import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tracking.dart';
import '../models/map_marker.dart';
import '../tracking_providers.dart';
import '../widgets/map_thumbnail_card.dart';

/// MAP PAGE
/// 
/// Tujuan: Menampilkan peta dengan marker untuk setiap foto/lokasi
/// Route: /map
/// Arguments: (optional) Tracking object untuk highlight satu lokasi
/// 
/// State Management:
/// - trackingListProvider: FutureProvider untuk get semua tracking dari repository
/// - selectedTrackingProvider: StateNotifierProvider untuk tracking yang dipilih
/// 
/// Fitur:
/// - Map placeholder dengan marker skeleton (loop tracking → MapMarker)
/// - Horizontal thumbnail list di bawah dengan scroll
/// - Saat thumbnail di-tap, update selectedTracking
/// - Saat marker di-tap (simulasi), update selectedTracking
class MapPage extends ConsumerWidget {
  // Optional: untuk highlight satu foto tertentu saat pertama kali open
  final Tracking? highlightedTracking;

  const MapPage({
    super.key,
    this.highlightedTracking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch tracking list dari provider
    final trackingListAsync = ref.watch(trackingListProvider);
    // Watch selected tracking
    final selectedTracking = ref.watch(selectedTrackingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        elevation: 0,
      ),
      body: trackingListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(trackingListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (trackings) {
          if (trackings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada tracking data',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          // Convert trackings ke MapMarker models
          final markers = trackings
              .map((tracking) => MapMarker.fromTracking(tracking))
              .toList();

          return Column(
            children: [
              // ================================================================
              // MAP CONTAINER (PLACEHOLDER)
              // ================================================================
              Expanded(
                child: _buildMapPlaceholder(
                  context,
                  markers,
                  selectedTracking.tracking,
                  ref,
                ),
              ),

              // ================================================================
              // BOTTOM SHEET - Horizontal Thumbnail List
              // ================================================================
              _buildThumbnailList(
                context,
                trackings,
                selectedTracking.tracking,
                ref,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build map placeholder dengan marker skeleton
  /// 
  /// Ini adalah placeholder untuk:
  /// - GoogleMap widget (dari google_maps_flutter)
  /// - FlutterMap widget (dari flutter_map)
  /// - Atau custom canvas-based map
  Widget _buildMapPlaceholder(
    BuildContext context,
    List<MapMarker> markers,
    Tracking? selectedTracking,
    WidgetRef ref,
  ) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Map icon
          const Icon(Icons.map, size: 64, color: Colors.grey),
          const SizedBox(height: 16),

          // Info: Map widget akan ditaruh di sini
          const Text(
            'Map widget integration here',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Text(
            '(GoogleMap or FlutterMap)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // ====== MARKER SKELETON INFO ======
          // Tampilkan informasi marker yang sudah ter-parse
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marker Summary (${markers.length} markers)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // List markers sebagai info
                ...markers.take(3).map((marker) {
                  final isSelected = selectedTracking?.id == marker.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        // Simulasi marker tap
                        ref
                            .read(selectedTrackingProvider.notifier)
                            .selectTracking(marker.trackingSource);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                marker.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.blue : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Text(
                              '(${marker.latitude.toStringAsFixed(3)}, ${marker.longitude.toStringAsFixed(3)})',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                if (markers.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... and ${markers.length - 3} more markers',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Tap marker info di atas untuk select, atau tap thumbnail di bawah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build horizontal thumbnail list di bottom sheet
  Widget _buildThumbnailList(
    BuildContext context,
    List<Tracking> trackings,
    Tracking? selectedTracking,
    WidgetRef ref,
  ) {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trackings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${trackings.length} photos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal list of thumbnails
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trackings.length,
              itemBuilder: (context, index) {
                final tracking = trackings[index];
                final isSelected = selectedTracking?.id == tracking.id;

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 12 : 4,
                    right: index == trackings.length - 1 ? 12 : 4,
                  ),
                  child: MapThumbnailCard(
                    tracking: tracking,
                    isSelected: isSelected,
                    onTap: () {
                      // Update selected tracking
                      ref
                          .read(selectedTrackingProvider.notifier)
                          .selectTracking(tracking);

                      // TODO: Implement scroll to location
                      // When integrating actual map library (google_maps_flutter or flutter_map):
                      // - Use CameraUpdateOptions to animate camera to marker location
                      // - Example for google_maps_flutter:
                      //   mapController?.animateCamera(
                      //     CameraUpdate.newLatLng(
                      //       LatLng(tracking.latitude, tracking.longitude),
                      //     ),
                      //   );
                      // - Example for flutter_map:
                      //   _mapController.move(
                      //     LatLng(tracking.latitude, tracking.longitude),
                      //     _mapController.camera.zoom,
                      //   );
                    },
                  ),
                );
              },
            ),
          ),

          // Selected tracking info (optional, untuk debugging)
          if (selectedTracking != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: const Border(
                  top: BorderSide(color: Colors.blue),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedTracking.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
