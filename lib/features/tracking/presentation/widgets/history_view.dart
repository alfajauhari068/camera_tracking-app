import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/history_item.dart';

enum HistoryFilterType { all, reports, snapshots }


extension _HistoryFilterTypeLabel on HistoryFilterType {
  String get label {
    switch (this) {
      case HistoryFilterType.all:
        return 'Semua';
      case HistoryFilterType.reports:
        return 'Laporan Masalah';
      case HistoryFilterType.snapshots:
        return 'Snapshots';
    }
  }
}

class HistoryView extends StatefulWidget {
  final List<HistoryItem> items;
  final HistoryFilterType selectedFilter;
  final String searchText;
  final DateTime? selectedDate;
  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<HistoryFilterType> onFilterChanged;
  final VoidCallback onDateTap;
  final VoidCallback onClearFilters;
  final ValueChanged<HistoryItem> onItemTap;
  final ValueChanged<HistoryItem> onItemLongPress;
  final ValueChanged<HistoryItem> onCopyCoordinates;
  final ValueChanged<HistoryItem> onDetailPressed;

  const HistoryView({
    super.key,
    required this.items,
    required this.selectedFilter,
    required this.searchText,
    required this.selectedDate,
    required this.selectionMode,
    required this.selectedIds,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onDateTap,
    required this.onClearFilters,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onCopyCoordinates,
    required this.onDetailPressed,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final TextEditingController _searchController;
  String? _slidingDetailId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _searchController = TextEditingController(text: widget.searchText);
  }

  @override
  void didUpdateWidget(covariant HistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText &&
        widget.searchText != _searchController.text) {
      _searchController.text = widget.searchText;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _applyFilters(widget.items);
    final totalCount = widget.items.length;
    final filteredCount = filteredItems.length;
    final reportCount = widget.items.where((item) => item.isReporting).length;
    final snapshotCount = widget.items
        .where((item) => item.status == HistoryStatus.snapshot)
        .length;
    final isFiltered = widget.selectedFilter != HistoryFilterType.all ||
        widget.searchText.isNotEmpty ||
        widget.selectedDate != null;

    return Container(
      color: const Color(0xFF0F1117),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: _buildLiveHeader(totalCount, filteredCount, isFiltered),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildSearchAndDate(context)),
          SliverToBoxAdapter(child: const SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: _buildFilterChips(reportCount, snapshotCount),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 10)),
          if (filteredItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(totalCount, filteredCount, isFiltered),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList.separated(
                itemCount: filteredItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _HistoryLogCard(
                    key: ValueKey(item.id),
                    item: item,
                    isSelected: widget.selectedIds.contains(item.id),
                    selectionMode: widget.selectionMode,
                    onTap: () => widget.onItemTap(item),
                    onLongPress: () => widget.onItemLongPress(item),
                    onCopy: () => widget.onCopyCoordinates(item),
                    onDetail: () => _handleDetailPress(item),
                    isSliding: _slidingDetailId == item.id,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<HistoryItem> _applyFilters(List<HistoryItem> items) {
    return items.where((item) {
      if (widget.selectedFilter == HistoryFilterType.reports && !item.isReporting) {
        return false;
      }
      if (widget.selectedFilter == HistoryFilterType.snapshots &&
          item.status != HistoryStatus.snapshot) {
        return false;
      }
      if (widget.searchText.isNotEmpty) {
        final query = widget.searchText.toLowerCase();
        if (!item.locationSummary.toLowerCase().contains(query) &&
            !item.coordinatesDisplay.toLowerCase().contains(query) &&
            !item.formattedDate.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (widget.selectedDate != null) {
        final date = widget.selectedDate!;
        if (item.timestamp.year != date.year ||
            item.timestamp.month != date.month ||
            item.timestamp.day != date.day) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildLiveHeader(int totalCount, int filteredCount, bool isFiltered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glow = 0.4 + (_pulseController.value * 0.35);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF8D),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF8D).withAlpha((glow * 255).round()),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      'DATABASE LIVE',
                      style: const TextStyle(
                        color: Color(0xFF0B1B0E),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isFiltered
                      ? 'Menampilkan $filteredCount dari $totalCount log'
                      : '$totalCount baris log tersedia',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSearchAndDate(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: widget.onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari lokasi atau koordinat...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF151B26),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF66E2FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.onDateTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF151B26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A3B52)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF66E2FF), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.selectedDate == null
                        ? 'Tanggal'
                        : '${widget.selectedDate!.day.toString().padLeft(2, '0')}/${widget.selectedDate!.month.toString().padLeft(2, '0')}/${widget.selectedDate!.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (widget.selectedDate != null || widget.searchText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onTap: widget.onClearFilters,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241C36),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Color(0xFF00FF8D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(int reportCount, int snapshotCount) {
    final filterData = [
      HistoryFilterType.all,
      HistoryFilterType.reports,
      HistoryFilterType.snapshots,
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filterData.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filterData[index];
          final selected = filter == widget.selectedFilter;
          final count = switch (filter) {
            HistoryFilterType.all => widget.items.length,
            HistoryFilterType.reports => reportCount,
            HistoryFilterType.snapshots => snapshotCount,
          };
          final color = switch (filter) {
            HistoryFilterType.all => const Color(0xFF4D6583),
            HistoryFilterType.reports => const Color(0xFFBF8D00),
            HistoryFilterType.snapshots => const Color(0xFF2BC7F4),
          };

          return ChoiceChip(
            selected: selected,
            onSelected: (_) => widget.onFilterChanged(filter),
            labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            label: Row(
              children: [
                Text(
                  '${filter.label} ',
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.black.withAlpha((0.12 * 255).round())
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            selectedColor: color,
            backgroundColor: const Color(0xFF161B24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: color.withAlpha((0.35 * 255).round())),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(int totalCount, int filteredCount, bool isFiltered) {
    if (!isFiltered || totalCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada log',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai ambil foto atau laporkan masalah untuk melihat riwayat di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_off, size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada log sesuai filter',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Menampilkan $filteredCount dari $totalCount log. Hapus filter untuk melihat semua.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF8D),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.onClearFilters,
            child: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }

  void _handleDetailPress(HistoryItem item) {
    setState(() => _slidingDetailId = item.id);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      widget.onDetailPressed(item);
      setState(() => _slidingDetailId = null);
    });
  }
}

class _HistoryLogCard extends StatelessWidget {
  final HistoryItem item;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onCopy;
  final VoidCallback onDetail;
  final bool isSliding;

  const _HistoryLogCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onCopy,
    required this.onDetail,
    required this.isSliding,
  });

  @override
  Widget build(BuildContext context) {
    final isReporting = item.isReporting;
    const amberAccent = Color(0xFFFFC107);
    const cyanAccent = Color(0xFF36C6FF);
    final accentColor = isReporting ? amberAccent : cyanAccent;

    final cardColor = isSelected ? const Color(0xFF1F2937) : const Color(0xFF121623);

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 130),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2B3550), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 130,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              _buildThumbnail(),
              const SizedBox(width: 12),
              Expanded(child: _buildCardContent(accentColor, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 72,
        color: const Color(0xFF1D2430),
        child: FutureBuilder<String?>(
          future: _resolveImagePath(item.imagePath, item.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)));
            }
            final resolved = snapshot.data;
            if (resolved != null && resolved.isNotEmpty) {
              return Image.file(
                File(resolved),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white24,
                ),
              );
            }
            return const Icon(Icons.location_pin, color: Colors.white54, size: 36);
          },
        ),
      ),
    );
  }

  Future<String?> _resolveImagePath(String? imagePath, String id) async {
    try {
      if (imagePath != null && imagePath.isNotEmpty) {
        final orig = File(imagePath);
        if (orig.existsSync()) return imagePath;
      }

      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/images');
      if (!imagesDir.existsSync()) return null;

      final files = imagesDir.listSync();
      for (final f in files) {
        if (f is File) {
          final name = p.basenameWithoutExtension(f.path);
          if (name == id) return f.path;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget _buildCardContent(Color accentColor, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.locationSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.isReporting ? 'Laporan' : 'Snapshot',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${item.formattedDate} · ${item.formattedTime}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          item.coordinatesDisplay,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onCopy,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF181F2C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.copy, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Copy',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSlide(
              offset: isSliding ? const Offset(0.12, 0) : Offset.zero,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: const Size(104, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onDetail,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Detail',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
