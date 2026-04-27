import 'package:flutter/material.dart';

/// GALLERY PAGE
/// 
/// Tujuan: Menampilkan daftar foto dalam grid/list dengan pencarian
/// Route: /gallery
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  // State untuk search/filter
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                hintText: 'Search photos...',
                prefixIcon: const Icon(Icons.search),
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
          // PHOTO GRID
          // ===================================================================
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 0, // TODO: Connect to Riverpod provider untuk get photos
              itemBuilder: (context, index) {
                // TODO: Placeholder photo card
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
