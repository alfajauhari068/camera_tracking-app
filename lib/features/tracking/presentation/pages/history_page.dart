import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/entities/tracking.dart';
import '../providers.dart';
import '../tracking_providers.dart';
import '../widgets/report_badge.dart';

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
  bool _showReportsOnly = false;

  /// Selection untuk delete
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};

  List<HistoryItem> _mapToHistoryItems(List<Tracking> trackings) {
    return trackings.map((t) {
      return HistoryItem(
        id: t.id,
        timestamp: t.timestamp,
        locationSummary: t.address.isNotEmpty
            ? t.address
            : '${t.latitude}, ${t.longitude}',
        status: HistoryStatus.snapshot,
        latitude: t.latitude,
        longitude: t.longitude,
        imagePath: t.imagePath,
        isReporting: t.type == TrackingType.reporting,
        reportCategory: t.reportInfo?.category,
          reportSeverity: t.reportInfo?.severity,
      );
    }).toList();
  }

  List<HistoryItem> _filterItems(List<HistoryItem> items) {
    var filtered = items;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.locationSummary.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedDate != null) {
      filtered = filtered.where((item) {
        return item.timestamp.year == _selectedDate!.year &&
            item.timestamp.month == _selectedDate!.month &&
            item.timestamp.day == _selectedDate!.day;
      }).toList();
    }

    if (_showReportsOnly) {
      filtered = filtered.where((item) => item.isReporting).toList();
    }

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final trackingListAsync = ref.watch(trackingListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterArea(),
          Expanded(
            child: trackingListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Gagal memuat history\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              data: (trackings) {
                final allItems = _mapToHistoryItems(trackings);
                final filteredItems = _filterItems(allItems);
                return _buildBody(filteredItems);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<HistoryItem> items) {
    if (items.isEmpty) {
      if (_selectionMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectionMode = false;
            _selectedIds.clear();
          });
        });
      }
      return _buildEmptyState();
    }

    return _buildHistoryList(items);
  }

  Widget _buildFilterArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1e1e1e),
      child: Column(
        children: [
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
          Row(
            children: [
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
              FilterChip(
                label: const Text('Hanya Laporan'),
                selected: _showReportsOnly,
                selectedColor: Colors.orangeAccent.withOpacity(0.2),
                backgroundColor: const Color(0xFF2c2c2c),
                labelStyle: TextStyle(
                  color: _showReportsOnly ? Colors.orangeAccent : Colors.white70,
                ),
                onSelected: (selected) {
                  setState(() => _showReportsOnly = selected);
                },
              ),
              const Spacer(),
              if (_selectedDate != null || _searchQuery.isNotEmpty || _showReportsOnly)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Color(0xFF00e676)),
                  ),
                ),
              const Spacer(),
              Text(
                ' ',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          selectionMode: _selectionMode,
          onTap: () => _onItemTap(item),
          onLongPress: () => _onItemLongPress(item),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Colors.white70,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada riwayat foto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ambil foto terlebih dahulu untuk melihat tracking di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Buka Kamera'),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.camera);
            },
          ),
        ],
      ),
    );
  }

  void _onItemTap(HistoryItem item) {
    if (_selectionMode) {
      setState(() {
        if (_selectedIds.contains(item.id)) {
          _selectedIds.remove(item.id);
        } else {
          _selectedIds.add(item.id);
        }
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      });
      return;
    }

    _showItemDetail(item);
  }

  void _onItemLongPress(HistoryItem item) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(item.id);
    });
  }

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
      _showReportsOnly = false;
    });
  }

  AppBar _buildAppBar() {
    if (!_selectionMode) {
      return AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF1a237e),
        elevation: 0,
      );
    }

    return AppBar(
      leading: IconButton(
        tooltip: 'Batal',
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedIds.length} terpilih'),
      actions: [
        IconButton(
          tooltip: 'Hapus',
          icon: const Icon(Icons.delete_outline),
          onPressed: _deleteSelected,
        ),
      ],
      backgroundColor: const Color(0xFF1a237e),
      elevation: 0,
    );
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final idsToDelete = _selectedIds.toList(growable: false);
    if (idsToDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${idsToDelete.length} foto?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(trackingRepositoryProvider);
      for (final id in idsToDelete) {
        await repo.deleteTracking(id);
      }

      if (!mounted) return;
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
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
    Navigator.pushNamed(context, AppRoutes.detail, arguments: item.id);
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
    final isReporting = item.isReporting;
    final statusColor = isReporting
        ? Colors.orangeAccent
        : isTracking
            ? const Color(0xFF00e676)
            : const Color(0xFF64b5f6);

    final statusText = isReporting
        ? 'REPORT'
        : isTracking
            ? 'Tracking'
            : 'Snapshot';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF24303A) : const Color(0xFF1e1e1e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00e676) : Colors.transparent,
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
                          child: Image.file(
                            File(item.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.location_on, color: Colors.grey),
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                      if (isReporting && item.reportSeverity?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Severity: ${_formatSeverity(item.reportSeverity)}',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // RIGHT: Status Badge
                if (isReporting)
                  const ReportBadge()
                else
                  Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha((0.2 * 255).round()),
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
            if (selectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: isSelected
                      ? const Color(0xFF00e676)
                      : Colors.white12,
                  child: Icon(
                    isSelected ? Icons.check : Icons.radio_button_unchecked,
                    size: 16,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatSeverity(String? severity) {
    if (severity == null || severity.isEmpty) return '-';

    switch (severity.toLowerCase()) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      default:
        return severity[0].toUpperCase() + severity.substring(1);
    }
  }
}
