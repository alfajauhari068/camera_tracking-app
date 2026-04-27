import 'package:flutter/material.dart';

import '../../domain/entities/tracking.dart';

/// MAP PAGE
/// 
/// Tujuan: Menampilkan peta dengan marker untuk setiap foto/lokasi
/// Route: /map
/// Arguments: (optional) Tracking object untuk highlight satu lokasi
class MapPage extends StatelessWidget {
  // Optional: untuk highlight satu foto tertentu
  final Tracking? highlightedTracking;

  const MapPage({
    super.key,
    this.highlightedTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ===================================================================
          // MAP CONTAINER (Placeholder - nanti ganti dengan actual map widget)
          // ===================================================================
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Map widget integration here',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '(FlutterMap or GoogleMap)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===================================================================
          // BOTTOM SHEET - Recent Photos di Lokasi Ini
          // ===================================================================
          Container(
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
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Recent Photos at This Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 0, // TODO: Connect ke provider
                    itemBuilder: (context, index) {
                      // TODO: Photo thumbnail card
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                      );
                    },
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
