import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/tracking.dart';
import '../tracking_providers.dart';
import '../widgets/map_thumbnail_card.dart';

/// MAP PAGE dengan FlutterMap dan user location permission support
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final trackingListAsync = ref.watch(trackingListProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final selectedTracking = ref.watch(selectedTrackingProvider).tracking;

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: trackingListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading tracking data:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (trackings) {
          if (trackings.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No tracking data available.\nPlease capture a photo first.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final centerPoint = LatLng(
            trackings.first.latitude,
            trackings.first.longitude,
          );
          final markers = trackings.map((tracking) {
            final isSelectedMarker = selectedTracking?.id == tracking.id;
            return Marker(
              width: isSelectedMarker ? 42 : 32,
              height: isSelectedMarker ? 42 : 32,
              point: LatLng(tracking.latitude, tracking.longitude),
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(selectedTrackingProvider.notifier)
                      .selectTracking(tracking);
                },
                child: Icon(
                  Icons.location_on,
                  color: isSelectedMarker ? Colors.blue : Colors.red,
                  size: isSelectedMarker ? 38 : 32,
                ),
              ),
            );
          }).toList();

          if (userLocationAsync.value != null) {
            markers.add(
              Marker(
                width: 34,
                height: 34,
                point: LatLng(
                  userLocationAsync.value!.latitude,
                  userLocationAsync.value!.longitude,
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blueAccent,
                  size: 28,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centerPoint,
                    initialZoom: 14,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'camera_tracking_gps',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: trackings.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final tracking = trackings[index];
                    final isSelected = selectedTracking?.id == tracking.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: MapThumbnailCard(
                        tracking: tracking,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedTrackingProvider.notifier)
                              .selectTracking(tracking);
                          _mapController.move(
                            LatLng(tracking.latitude, tracking.longitude),
                            15,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
