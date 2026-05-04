import 'package:flutter/material.dart';

import '../../domain/entities/history_item.dart';

/// =============================================================================
/// HISTORY PAGE - Daftar Tracking Log
/// =============================================================================
/// 
/// Fungsi:
/// - Menampilkan daftar history tracking/foto
/// - Search by location/text
/// - Filter by date
/// 
/// Route: /history
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Search & filter state
  String _searchQuery = '';
  DateTime? _selectedDate;

  // Dummy data (replace with real provider in production)
  final List<HistoryItem> _allItems = HistoryItemDummy.getDummyList();

  // Filtered items
  List<HistoryItem> get _filteredItems {
    var items = _allItems;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) {
        return item.locationSummary.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by date
    if (_selectedDate != null) {
      items = items.where((item) {
        return item.timestamp.year == _selectedDate!.year &&
               item.timestamp.month == _selectedDate!.month &&
               item.timestamp.day == _selectedDate!.day;
      }).toList();
    }

    // Sort by timestamp descending (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),  // Dark background
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF1a237e),  // Navy
        elevation: 0,
      ),
      body: Column(
        children: [
          // ===================================================================
          // FILTER AREA - Search + Date Picker
          // ===================================================================
          _buildFilterArea(),

          // ===================================================================
          // HISTORY LIST
          // ===================================================================
          Expanded(
            child: _filteredItems.isEmpty 
                ? _buildEmptyState() 
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // FILTER AREA
  // =========================================================================

  Widget _buildFilterArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1e1e1e),  // Dark grey
      child: Column(
        children: [
          // Row: Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari lokasi...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF2c2c2c),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),

          const SizedBox(height: 8),

          // Row: Date Filter + Clear Filter
          Row(
            children: [
              // Date Picker Button
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _selectedDate != null 
                      ? _formatDate(_selectedDate!)
                      : 'Semua Tanggal',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              const SizedBox(width: 8),

              // Clear Filter
              if (_selectedDate != null || _searchQuery.isNotEmpty)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Color(0xFF00e676)),
                  ),
                ),

              const Spacer(),

              // Item count
              Text(
                '${_filteredItems.length} item',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // HISTORY LIST
  // =========================================================================

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _HistoryListItem(
          item: item,
          onTap: () => _showItemDetail(item),
        );
      },
    );
  }

  // =========================================================================
  // EMPTY STATE
  // =========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _selectedDate == null
                ? 'Belum ada history'
                : 'Tidak ada hasil',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ACTIONS
  // =========================================================================

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00e676),  // Neon green accent
              surface: Color(0xFF1e1e1e),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
    });
  }

  void _showItemDetail(HistoryItem item) {
    // TODO: Navigate to detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item: ${item.locationSummary}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}';
  }
}

// =============================================================================
// HISTORY LIST ITEM WIDGET
// =============================================================================

class _HistoryListItem extends StatelessWidget {
  final HistoryItem item;
  final VoidCallback onTap;

  const _HistoryListItem({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTracking = item.status == HistoryStatus.trackingSession;
    final statusColor = isTracking 
        ? const Color(0xFF00e676)  // Neon green
        : const Color(0xFF64b5f6);   // Blue
    
    final statusText = isTracking ? 'Tracking' : 'Snapshot';

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e1e),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // ===================================================================
            // LEFT: Image/Icon
            // ===================================================================
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2c2c2c),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                    ),
            ),

            const SizedBox(width: 12),

            // ===================================================================
            // CENTER: Content
            // ===================================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Date + Time
                  Row(
                    children: [
                      Text(
                        item.formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.formattedTime,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location
                  Text(
                    item.locationSummary,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Coordinates ( jika ada)
                  Text(
                    item.coordinatesDisplay,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // ===================================================================
            // RIGHT: Status Badge
            // ===================================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
