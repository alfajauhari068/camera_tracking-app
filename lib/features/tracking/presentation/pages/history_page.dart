import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/entities/tracking.dart';
import '../providers.dart';
import '../tracking_providers.dart';
import '../widgets/history_view.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final _ = ref.refresh(trackingListProvider);
    });
  }

  // Referensi provider repository sudah disediakan lewat ../providers.dart

  // Search & filter state
  String _searchQuery = '';
  DateTime? _selectedDate;
  HistoryFilterType _selectedFilter = HistoryFilterType.all;

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

  @override
  Widget build(BuildContext context) {
    final trackingListAsync = ref.watch(trackingListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: trackingListAsync.when(
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
          return HistoryView(
            items: allItems,
            selectedFilter: _selectedFilter,
            searchText: _searchQuery,
            selectedDate: _selectedDate,
            selectionMode: _selectionMode,
            selectedIds: _selectedIds,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            onDateTap: _pickDate,
            onClearFilters: _clearFilters,
            onItemTap: _onItemTap,
            onItemLongPress: _onItemLongPress,
            onCopyCoordinates: _copyCoordinates,
            onDetailPressed: _showItemDetail,
          );
        },
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
      _selectedFilter = HistoryFilterType.all;
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

  void _copyCoordinates(HistoryItem item) {
    final coordinates = '${item.latitude}, ${item.longitude}';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Koordinat disalin ke clipboard'),
      ),
    );
  }

  void _showItemDetail(HistoryItem item) {
    Navigator.pushNamed(context, AppRoutes.detail, arguments: item.id);
  }
}
