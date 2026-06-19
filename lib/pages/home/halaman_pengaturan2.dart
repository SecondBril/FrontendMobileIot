import 'package:flutter/material.dart';

class HalamanPengaturan extends StatefulWidget {
  final VoidCallback onBukaHalamanNotifikasi;

  const HalamanPengaturan({super.key, required this.onBukaHalamanNotifikasi});

  @override
  State<HalamanPengaturan> createState() => _HalamanPengaturanState();
}

class _HalamanPengaturanState extends State<HalamanPengaturan> {
  double _lowFeedThresholdPct = 20;
  double _lowWaterThresholdPct = 25;
  bool _phWarningEnabled = true;
  bool _systemErrorEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          const Text(
            'Pengaturan Perangkat & Sistem',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildDeviceSettingsCard(),
          const SizedBox(height: 20),
          const Text(
            'Kalibrasi Sensor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSensorCalibrationCard(),
          const SizedBox(height: 20),
          const Text(
            'Pengaturan Notifikasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildNotificationSettingsCard(context),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pengaturan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: widget.onBukaHalamanNotifikasi,
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSettingsCard() {
    return _baseCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wifi_tethering, color: Color(0xFF16A34A)),
            title: const Text('Status Perangkat'),
            subtitle: const Text('Terhubung'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ),
          const Divider(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wifi, color: Color(0xFF0EA5E9)),
            title: const Text('Jaringan WiFi'),
            subtitle: const Text('FarmWiFi-5G'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.restart_alt, color: Color(0xFFF97316)),
                    SizedBox(width: 8),
                    Text('Mulai Ulang Perangkat'),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Restart'),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.memory, color: Color(0xFF6B7280)),
            title: const Text('Versi Firmware'),
            subtitle: const Text('v2.1.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCalibrationCard() {
    return _baseCard(
      child: Column(
        children: [
          _sensorRow(
            icon: Icons.scale_outlined,
            title: 'Kalibrasi Sensor Pakan',
            subtitle: 'Sensor load cell',
          ),
          const Divider(height: 8),
          _sensorRow(
            icon: Icons.water_drop_outlined,
            title: 'Kalibrasi Level Air',
            subtitle: 'Sensor ultrasonik',
          ),
          const Divider(height: 8),
          _sensorRow(
            icon: Icons.science_outlined,
            title: 'Kalibrasi pH Air',
            subtitle: 'Sensor pH',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard(BuildContext context) {
    return _baseCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF22C55E),
            ),
            title: const Text('Notifikasi Pakan Rendah'),
            subtitle: Text(
              'Beritahu ketika di bawah ${_lowFeedThresholdPct.toStringAsFixed(0)}%',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdSheet(
              context,
              title: 'Ambang Notifikasi Pakan Rendah',
              unit: '%',
              value: _lowFeedThresholdPct,
              min: 5,
              max: 50,
              divisions: 45,
              onSave: (v) => setState(() => _lowFeedThresholdPct = v),
            ),
          ),
          const Divider(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.water_drop_outlined,
              color: Color(0xFF0EA5E9),
            ),
            title: const Text('Notifikasi Air Rendah'),
            subtitle: Text(
              'Beritahu ketika di bawah ${_lowWaterThresholdPct.toStringAsFixed(0)}%',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThresholdSheet(
              context,
              title: 'Ambang Notifikasi Air Rendah',
              unit: '%',
              value: _lowWaterThresholdPct,
              min: 5,
              max: 60,
              divisions: 55,
              onSave: (v) => setState(() => _lowWaterThresholdPct = v),
            ),
          ),
          const Divider(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.warning_amber_outlined,
              color: Color(0xFFF97316),
            ),
            title: const Text('Notifikasi pH Tidak Normal'),
            value: _phWarningEnabled,
            onChanged: (v) => setState(() => _phWarningEnabled = v),
            activeColor: const Color(0xFF16A34A),
          ),
          const Divider(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
            ),
            title: const Text('Notifikasi Error Sistem'),
            value: _systemErrorEnabled,
            onChanged: (v) => setState(() => _systemErrorEnabled = v),
            activeColor: const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  void _showThresholdSheet(
    BuildContext context, {
    required String title,
    required String unit,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required void Function(double v) onSave,
  }) {
    double temp = value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ambang: ${temp.toStringAsFixed(0)}$unit',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: temp.clamp(min, max),
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: '${temp.toStringAsFixed(0)}$unit',
                    activeColor: const Color(0xFF16A34A),
                    onChanged: (v) => setState(() => temp = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            onSave(temp);
                            Navigator.pop(context);
                          },
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sensorRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF16A34A)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Normal',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF16A34A),
          ),
        ),
      ),
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
