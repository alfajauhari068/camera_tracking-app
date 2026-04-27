import 'package:flutter/material.dart';

import '../../domain/entities/tracking.dart';

/// EXPORT PAGE
/// 
/// Tujuan: Memilih filter tanggal & format, kemudian export/share data
/// Route: /export
/// Arguments: (optional) Tracking object untuk preset filter satu foto
class ExportPage extends StatefulWidget {
  final Tracking? presetTracking;

  const ExportPage({
    super.key,
    this.presetTracking,
  });

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  // Form state
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFormat = 'CSV';
  bool _isExporting = false;
  String? _exportStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================================================================
            // DATE RANGE SECTION
            // ===================================================================
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Start date
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _startDate?.toString().split(' ')[0] ?? 'Select',
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // End date
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _endDate?.toString().split(' ')[0] ?? 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===================================================================
            // FORMAT SECTION
            // ===================================================================
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: ['CSV', 'XLSX', 'PDF', 'JSON'].map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFormat = value);
                }
              },
            ),

            const SizedBox(height: 24),

            // ===================================================================
            // GENERATE EXPORT BUTTON
            // ===================================================================
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
                label: Text(
                  _isExporting ? 'Exporting...' : 'Generate Export',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ===================================================================
            // STATUS MESSAGE
            // ===================================================================
            if (_exportStatus != null)
              Card(
                color: _exportStatus!.contains('berhasil')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _exportStatus!.contains('berhasil')
                            ? Icons.check_circle
                            : Icons.error,
                        color: _exportStatus!.contains('berhasil')
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _exportStatus!,
                          style: const TextStyle(fontSize: 12),
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

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /// Pick start date
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

  /// Pick end date
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

  /// Generate export
  Future<void> _generateExport() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Processing...';
    });

    try {
      // TODO: Implement actual export logic
      // - Call use case ExportPhotos
      // - Pass filters (_startDate, _endDate, _selectedFormat)
      // - Generate file
      // - Save ke storage

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _exportStatus =
            'Export berhasil! File tersimpan di /storage/emulated/0/CameraTracking/export_2026-04-27.$_selectedFormat';
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
