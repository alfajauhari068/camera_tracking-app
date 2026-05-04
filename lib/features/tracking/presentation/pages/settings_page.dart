import 'package:flutter/material.dart';
import 'package:camera_tracking_gps/core/models/settings_model.dart';
import 'package:camera_tracking_gps/core/services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsService _settingsService;
  late SettingsModel _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsService = SettingsService();
    await _settingsService.loadSettings();
    if (mounted) {
      setState(() {
        _settings = _settingsService.currentSettings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LOKASI & GPS
          _buildSection(
            title: '📍 Lokasi & GPS',
            children: [
              _buildSwitchTile(
                'Tampilkan koordinat detail',
                _settings.showCoordinatesInDetail,
                'Latitude & longitude di halaman foto',
                (value) async {
                  await _settingsService.updateShowCoordinatesInDetail(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
              _buildDropdownTile(
                'Mode akurasi',
                _settings.accuracyMode,
                ['standard', 'high'],
                'Standar lebih hemat baterai',
                (value) async {
                  await _settingsService.updateAccuracyMode(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
              _buildDropdownTile(
                'Sumber lokasi',
                _settings.locationSource,
                ['gpsAndNetwork', 'gpsOnly'],
                'GPS + jaringan lebih cepat',
                (value) async {
                  await _settingsService.updateLocationSource(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // FOTO & PENYIMPANAN
          _buildSection(
            title: '📸 Foto & Penyimpanan',
            children: [
              _buildDropdownTile(
                'Kualitas foto',
                _settings.photoQuality,
                ['medium', 'high', 'low'],
                'High = detail lebih, file lebih besar',
                (value) async {
                  await _settingsService.updatePhotoQuality(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
              _buildSwitchTile(
                'Duplikasi ke galeri',
                _settings.duplicateToGallery,
                'Foto juga disimpan di galeri sistem',
                (value) async {
                  await _settingsService.updateDuplicateToGallery(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // METADATA & TAMPILAN
          _buildSection(
            title: '📋 Metadata & Tampilan',
            children: [
              _buildDropdownTile(
                'Format tanggal',
                _settings.dateTimeFormat,
                ['24h_ddMMyyyy', '12h_yyyyMMdd'],
                'Format di foto & export',
                (value) async {
                  await _settingsService.updateDateTimeFormat(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // MAP & PETA
          _buildSection(
            title: '🗺️ Map & Peta',
            children: [
              _buildDropdownTile(
                'Jenis peta',
                _settings.mapType,
                ['standard', 'satellite'],
                'Default tampilan peta',
                (value) async {
                  await _settingsService.updateMapType(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
              _buildSwitchTile(
                'Tampilkan posisi saya',
                _settings.showMyLocationOnMap,
                'Marker lokasi perangkat di peta',
                (value) async {
                  await _settingsService.updateShowMyLocationOnMap(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // EXPORT
          _buildSection(
            title: '📤 Export & Laporan',
            children: [
              _buildDropdownTile(
                'Format ekspor',
                _settings.exportFormat,
                ['csv', 'xlsx'],
                'Format file download',
                (value) async {
                  await _settingsService.updateExportFormat(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // IDENTITAS
          _buildSection(
            title: '👤 Identitas Petugas',
            children: [
              _buildTextFieldTile(
                'Nama petugas',
                _settings.officerName,
                'Nama disemat di foto',
                (value) async {
                  await _settingsService.updateOfficerName(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
              _buildDropdownTile(
                'Proyek aktif',
                _settings.activeProject,
                ['Umum', 'Proyek A', 'Proyek B'],
                'Otomatis di metadata foto',
                (value) async {
                  await _settingsService.updateActiveProject(value);
                  setState(() => _settings = _settingsService.currentSettings);
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00e676),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1e1e1e),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    String subtitle,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey)),
      value: value,
      activeTrackColor: const Color(0xFF00e676),
      activeThumbImage: const AssetImage('assets/thumb_green.png'), // Optional
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    String subtitle,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey)),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF2d2d2d),
          style: const TextStyle(color: Colors.white),
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          )).toList(),
          onChanged: (newValue) => newValue != null ? onChanged(newValue) : null,
        ),
      ),
    );
  }

  Widget _buildTextFieldTile(
    String title,
    String value,
    String subtitle,
    ValueChanged<String> onChanged,
  ) {
    final controller = TextEditingController(text: value);
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey)),
      trailing: SizedBox(
        width: 150,
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            fillColor: const Color(0xFF2d2d2d),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

