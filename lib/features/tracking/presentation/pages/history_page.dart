import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/entities/tracking.dart';
import '../providers.dart';
import '../tracking_providers.dart';


/// =============================================================================
/// HISTORY PAGE - Daftar Tracking Log
/// =============================================================================
///
/// Fungsi:
/// - Menampilkan daftar history tracking/foto (berdasarkan data repository)
/// - Search by location/text
/// - Filter by date
///
/// Route: /history
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {

  // Referensi provider repository sudah disediakan lewat ../providers.dart

  // Search & filter state
  String _searchQuery = '';
  DateTime? _selectedDate;

  /// Selection untuk delete
  final Set<String> _selectedIds = <String>{};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  // Convert domain Tracking list to HistoryItem list with mapping for existing UI.
  List<HistoryItem> _mapToHistoryItems(List<Tracking> trackings) {
    return trackings.map((t) {
      return HistoryItem(
        id: t.id,
        timestamp: t.timestamp,
        locationSummary: t.address.isNotEmpty
            ? t.address
            : '${t.latitude}, ${t.longitude}',
        status: HistoryStatus.snapshot, // default; UI hanya butuh badge
        latitude: t.latitude,
        longitude: t.longitude,
        imagePath: t.imagePath,
      );
    }).toList();
  }

  List<HistoryItem> _filterItems(List<HistoryItem> items) {
    var filtered = items;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.locationSummary.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by date
    if (_selectedDate != null) {
      filtered = filtered.where((item) {
        return item.timestamp.year == _selectedDate!.year &&
            item.timestamp.month == _selectedDate!.month &&
            item.timestamp.day == _selectedDate!.day;
      }).toList();
    }

    // Sort by timestamp descending (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final trackingListAsync = ref.watch(trackingListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF1a237e), // Navy
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isSelectionMode)
            _buildSelectionToolbar(),
          _buildFilterArea(),
          Expanded(

            child: trackingListAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load history\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              data: (trackings) {
                final allItems = _mapToHistoryItems(trackings);
                final filteredItems = _filterItems(allItems);

                if (filteredItems.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildHistoryList(filteredItems);
              },
            ),
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
      color: const Color(0xFF1e1e1e), // Dark grey
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) =>
                setState(() => _searchQuery = value),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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

              // Item count Placeholder (bisa diisi nanti)
              Text(
                ' ',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
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

  Widget _buildHistoryList(List<HistoryItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedIds.contains(item.id);

        return _HistoryListItem(
          item: item,
          isSelected: isSelected,
          selectionMode: _isSelectionMode,
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(item.id);
                } else {
                  _selectedIds.add(item.id);
                }
              });
              return;
            }
            _showItemDetail(item);
          },
          onLongPress: () {
            setState(() {
              _selectedIds.add(item.id);
            });
          },
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
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
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
              primary: Color(0xFF00e676),
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

  Widget _buildSelectionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1a237e),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} dipilih',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Batal',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() => _selectedIds.clear());
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onPressed: _deleteSelected,
          ),
        ],
      ),
    );
  }


  Future<void> _deleteSelected() async {
    try {
      final ids = _selectedIds.toList(growable: false);
      if (ids.isEmpty) return;

      // konfirmasi sederhana
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hapus data'),
          content: Text('Hapus ${ids.length} foto/tracking yang dipilih?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final repo = ref.read(trackingRepositoryProvider);
      for (final id in ids) {
        await repo.deleteTracking(id);
      }

      if (!mounted) return;
      setState(() => _selectedIds.clear());
      ref.invalidate(trackingListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil menghapus data'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }


  void _showItemDetail(HistoryItem item) {
    // We don't have the full Tracking object here; PhotoDetailPage can load by ID.
    // Pass the HistoryItem id as the Tracking id.
    Navigator.pushNamed(
      context,
      AppRoutes.detail,
      arguments: item.id,
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
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _HistoryListItem({
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isTracking = item.status == HistoryStatus.trackingSession;
    final statusColor = isTracking
        ? const Color(0xFF00e676) // Neon green
        : const Color(0xFF64b5f6); // Blue

    final statusText = isTracking ? 'Tracking' : 'Snapshot';

    return InkWell(
      onTap: onTap,
      onLongPress: selectionMode ? onLongPress : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1e1e1e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00e676)
                : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // LEFT: Image/Icon
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

                // CENTER: Content
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

                      // Coordinates (jika ada)
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

                // RIGHT: Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
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
          ],
        ),
      ),
    );
  }
}