import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tracking.dart';
import '../tracking_providers.dart';
import '../widgets/photo_card.dart';

/// GALLERY PAGE
/// 
/// Tujuan: Menampilkan daftar foto dalam grid/list dengan pencarian
/// Route: /gallery
/// 
/// State management:
/// - Menggunakan FutureProvider (trackingListProvider) untuk load data async dari repository
/// - SearchQuery dikelola dengan local state (StatefulWidget)
/// - Filter dilakukan in-memory pada list dari provider
class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Watch trackingListProvider untuk mendapatkan semua tracking data
    final trackingListAsync = ref.watch(trackingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ===================================================================
          // SEARCH BAR
          // ===================================================================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan alamat atau tanggal...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // ===================================================================
          // PHOTO GRID (menggunakan FutureProvider dengan .when())
          // ===================================================================
          Expanded(
            child: trackingListAsync.when(
              // Loading state
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),

              // Error state
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Error: $error',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Invalidate provider untuk reload data
                        ref.invalidate(trackingListProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),

              // Data state
              data: (allTrackings) {
                // Filter trackings berdasarkan search query
                final filteredTrackings = _filterTrackings(allTrackings);

                if (filteredTrackings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tidak ada foto'
                              : 'Tidak ada hasil pencarian',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                // Build grid dari filtered trackings
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredTrackings.length,
                  itemBuilder: (context, index) {
                    final tracking = filteredTrackings[index];
                    return PhotoCard(
                      tracking: tracking,
                      onTap: () {
                        // Navigate to detail page with tracking data
                        Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: tracking,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Filter list Tracking berdasarkan search query
  /// 
  /// Logic:
  /// - Jika query kosong, return semua trackings
  /// - Jika ada query, filter berdasarkan address atau timestamp (case-insensitive)
  List<Tracking> _filterTrackings(List<Tracking> allTrackings) {
    if (_searchQuery.isEmpty) {
      return allTrackings;
    }

    final query = _searchQuery.toLowerCase();
    return allTrackings.where((tracking) {
      final addressMatch = tracking.address.toLowerCase().contains(query);
      final dateMatch = tracking.timestamp.toString().toLowerCase().contains(query);
      return addressMatch || dateMatch;
    }).toList();
  }
}
