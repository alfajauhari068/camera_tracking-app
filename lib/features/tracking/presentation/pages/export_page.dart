import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tracking.dart';
import '../../domain/usecases/export_trackings.dart';
import '../providers.dart';

/// EXPORT PAGE
///
/// Tujuan: Memilih filter tanggal & format, kemudian export/share data
/// Route: /export
/// Arguments: (optional) Tracking object untuk preset filter satu foto
class ExportPage extends ConsumerStatefulWidget {
  final Tracking? presetTracking;

  const ExportPage({super.key, this.presetTracking});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  // Form state
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFormat = 'CSV';
  bool _isExporting = false;
  String? _exportStatus;
  bool _initialized = false;
  Tracking? _presetTracking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _presetTracking = widget.presetTracking;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Tracking) {
      _presetTracking = args;
    }

    if (_presetTracking != null) {
      _startDate = DateTime(
        _presetTracking!.timestamp.year,
        _presetTracking!.timestamp.month,
        _presetTracking!.timestamp.day,
      );
      _endDate = _startDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: const Color(0xFF1a237e),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_presetTracking != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export preset untuk foto ini',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Alamat: ${_presetTracking!.address}'),
                      const SizedBox(height: 4),
                      Text(
                        'Tanggal: ${_presetTracking!.timestamp.toLocal().toString().split(' ')[0]}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF2c2c2c),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      child: Text(
                        _startDate?.toString().split(' ')[0] ?? 'Select',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF2c2c2c),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      child: Text(
                        _endDate?.toString().split(' ')[0] ?? 'Select',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Export Format',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedFormat,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2c2c2c),
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              dropdownColor: const Color(0xFF1e1e1e),
              style: const TextStyle(color: Colors.white),
              items: ['CSV', 'XLSX', 'PDF', 'JSON'].map((format) {
                return DropdownMenuItem(value: format, child: Text(format));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFormat = value);
                }
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _generateExport,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isExporting ? 'Exporting...' : 'Generate Export'),
              ),
            ),

            const SizedBox(height: 24),

            if (_exportStatus != null)
              Card(
                color: _exportStatus!.contains('berhasil')
                    ? const Color(0xFF1B5E20)
                    : const Color(0xFFB71C1C),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _exportStatus!.contains('berhasil')
                            ? Icons.check_circle
                            : Icons.error,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _exportStatus!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _generateExport() async {
    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      setState(() {
        _exportStatus = 'Start date tidak boleh setelah end date.';
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _exportStatus = 'Processing export...';
    });

    try {
      // temporary resolver: use repository+export usecase directly (avoids missing provider)
      final repo = ref.read(trackingRepositoryProvider);
      final exportService = ref.read(exportServiceProvider);
      final exporter = ExportTrackings(
        repository: repo,
        exportService: exportService,
      );
      final exportPath = await exporter.execute(
        startDate: _startDate,
        endDate: _endDate,
        format: _selectedFormat,
        trackingId: _presetTracking?.id,
      );

      setState(() {
        _exportStatus = 'Export berhasil! File tersimpan di $exportPath';
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _exportStatus = 'Export gagal: $e';
        _isExporting = false;
      });
    }
  }
}
