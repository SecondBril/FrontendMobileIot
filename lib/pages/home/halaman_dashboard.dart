import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_ui_challenge/utils/sensor_provider.dart';
import 'manual.dart';

class HalamanDashboard extends StatelessWidget {
  final VoidCallback onBukaMonitoring;
  final void Function(String id) onBukaNotifikasiDenganId;
  final VoidCallback onBukaHalamanNotifikasi;
  final VoidCallback onBukaHalamanMitra;

  const HalamanDashboard({
    super.key,
    required this.onBukaMonitoring,
    required this.onBukaNotifikasiDenganId,
    required this.onBukaHalamanNotifikasi,
    required this.onBukaHalamanMitra,
  });

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          _buildSystemStatusCard(),
          const SizedBox(height: 12),
          _buildStorageRow(
            levelPakanPersen: sensor.levelPakanPersen,
            levelAirPersen: sensor.levelAirPersen,
          ),
          const SizedBox(height: 12),
          _buildAiSummaryCard(context),
          const SizedBox(height: 12),
          _buildMitraInfoCard(),
          const SizedBox(height: 12),
          // _buildRecentAlertsCard(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Smart Poultry Feeder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Sistem Pakan Otomatis',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          IconButton(
            onPressed: onBukaHalamanNotifikasi,
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Sistem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Chip(
                backgroundColor: Color(0xFFD1FAE5),
                label: Text(
                  'Aktif',
                  style: TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_outline, size: 18, color: Colors.green),
              SizedBox(width: 6),
              Text(
                'Terakhir memberi pakan: 14.30 hari ini',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow({
      required double levelPakanPersen, 
      required double levelAirPersen
    }) {
      // Logika Kondisi (Sinkron dengan ambang batas Halaman Monitoring)
      final bool pakanAman = levelPakanPersen > 20.0;
      final bool airAman = levelAirPersen > 20.0;

      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onBukaMonitoring,
              child: _baseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Level Pakan', // Disingkat agar padat
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                        _miniStatChip(
                          icon: Icons.inventory_2_outlined,
                          label: 'Kondisi',
                          value: pakanAman ? 'Aman' : 'Kritis',
                          color: pakanAman ? const Color(0xFF16A34A) : Colors.red,
                        ),

                        const SizedBox(width: 6),

                        _miniStatChip(
                          icon: Icons.percent,
                          label: 'Level',
                          value: '${levelPakanPersen.toStringAsFixed(0)}%',
                          color: const Color(0xFF0EA5E9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onBukaMonitoring,
              child: _baseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Air', // Disingkat agar padat
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                        _miniStatChip(
                          icon: Icons.water_drop_outlined,
                          label: 'Kondisi',
                          value: airAman?'Aman' : 'Kritis',
                          color: airAman ? const Color(0xFF16A34A) : Colors.red,
                        ),

                        const SizedBox(width: 6),

                        _miniStatChip(
                          icon: Icons.percent,
                          label: 'Level',
                          value: '${levelAirPersen.toStringAsFixed(0)}%',
                          color: const Color(0xFF0EA5E9),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

Widget _buildAiSummaryCard(BuildContext context) { // Pastikan context tersedia untuk Navigator
    return GestureDetector(
      onTap: () => onBukaNotifikasiDenganId('ai_24'),
      child: _baseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perubahan dimulai di sini: Menggunakan Row untuk memisahkan Judul dan Tombol
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ringkasan Deteksi AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManualTelemetryPage(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Text(
                      'Manual Debug',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red, // Gunakan warna merah sebagai penanda ini bukan fitur untuk User
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Perubahan selesai
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF16A34A),
                    title: 'Status',
                    value: 'Aktif',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryItem(
                    icon: Icons.egg_alt,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Total Ayam',
                    value: '24 Ekor',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildRecentAlertsCard() {
  //   return _baseCard(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Notifikasi Terbaru',
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  //         ),
  //         const SizedBox(height: 12),
  //         GestureDetector(
  //           onTap: () => onBukaNotifikasiDenganId('auto_feed'),
  //           child: Container(
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFFE0F2FE),
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Row(
  //               children: const [
  //                 Icon(
  //                   Icons.notifications_active_outlined,
  //                   color: Color(0xFF0284C7),
  //                   size: 20,
  //                 ),
  //                 SizedBox(width: 8),
  //                 Expanded(
  //                   child: Text(
  //                     'Pakan otomatis berhasil diberikan. Tekan untuk lihat history.',
  //                     style: TextStyle(fontSize: 11, color: Colors.black87),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         _alertTile(
  //           icon: Icons.check_circle_outline,
  //           iconColor: const Color(0xFF16A34A),
  //           title: 'Pakan otomatis berhasil diberikan',
  //           subtitle: '10 menit yang lalu',
  //           onTap: () => onBukaNotifikasiDenganId('auto_feed'),
  //         ),
  //         const SizedBox(height: 10),
  //         _alertTile(
  //           icon: Icons.warning_amber_outlined,
  //           iconColor: const Color(0xFFF97316),
  //           title: 'Level air hampir habis - segera isi ulang',
  //           subtitle: '1 jam yang lalu',
  //           onTap: () => onBukaNotifikasiDenganId('low_water'),
  //         ),
  //         const SizedBox(height: 10),
  //         _alertTile(
  //           icon: Icons.visibility_outlined,
  //           iconColor: const Color(0xFF0EA5E9),
  //           title: 'Deteksi AI aktif - 24 ayam terdeteksi',
  //           subtitle: '2 jam yang lalu',
  //           onTap: () => onBukaNotifikasiDenganId('ai_24'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMitraInfoCard() {
    return GestureDetector(
      onTap: onBukaHalamanMitra,
      child: _baseCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/BinaInsaniii.jpeg',
                width: 54,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Mitra',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kelompok Tani Ternak Bina Insani',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lihat profil, alamat, dan informasi kemitraan',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
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

  Widget _miniStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
