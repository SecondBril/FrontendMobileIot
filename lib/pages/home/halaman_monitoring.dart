import 'package:flutter/material.dart';
import 'dart:async';
import '../../service/monitoring_api.dart';

class HalamanMonitoring extends StatefulWidget {
  final VoidCallback onBukaHalamanNotifikasi;
  final VoidCallback onBukaHistoryPakan;

  const HalamanMonitoring({
    super.key,
    required this.onBukaHalamanNotifikasi,
    required this.onBukaHistoryPakan,
  });

  @override
  State<HalamanMonitoring> createState() => _HalamanMonitoringState();
}

class _HalamanMonitoringState extends State<HalamanMonitoring> {
  Timer? _timer;
  bool isLoading = true;
  
  // STATE DINAMIS
  String phAir = '0.0';
  double levelPakanPersen = 0.0; // Menggunakan naming yang jelas
  double levelAirPersen = 0.0;   // Menggunakan naming yang jelas
  double beratPakanKg = 0.0;
  
  // State untuk AI
  bool isAyamTerdeteksi = false;
  String pesanAi = 'Menunggu data...';
  String waktuAi = '-';

  @override
  void initState() {
    super.initState();
    _loadDataSensor(); 
    
    // PERINGATAN: HTTP Polling ini adalah tumpukan teknis (tech debt). 
    // Ganti ke MQTT/WebSocket kelak untuk efisiensi server.
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadDataSensor();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDataSensor() async {
    final data = await MonitoringApiService.fetchLatestData();
    
    if (mounted) {
      setState(() {
        if (data != null) {
          phAir = data['ph_value']?.toString() ?? '0.0';
          // Menyesuaikan dengan key dari backend yang baru
          levelPakanPersen = (data['pakan_level_persen'] ?? 0).toDouble();
          levelAirPersen = (data['air_level_persen'] ?? 0).toDouble();
          
          beratPakanKg = (data['berat_loadcell_kg'] ?? 0.0).toDouble();
          isAyamTerdeteksi = data['ayam_terdeteksi'] ?? false;
          pesanAi = data['pesan_ai'] ?? (isAyamTerdeteksi ? 'Ayam terdeteksi' : 'Kandang kosong');
          waktuAi = data['waktu_deteksi_ai'] ?? 'Baru saja';
        }
        isLoading = false; 
      });
    }
  }

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
            'Monitoring Sensor',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          
          if (isLoading) 
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // _buildSensorValueCard(
            //   title: 'Berat Pakan (Load Cell)',
            //   statusText: beratPakanKg > 0.5 ? 'Normal' : 'Menipis',
            //   valueText: beratPakanKg.toStringAsFixed(2), 
            //   unitText: 'kg',
            // ),
            const SizedBox(height: 10),
            _buildLevelWithBarCard(
              title: 'Level Pakan (Ultrasonik)',
              // Batas peringatan diubah ke 20% (bukan lagi angka cm mentah)
              statusText: levelPakanPersen > 20.0 ? 'Normal' : 'Peringatan',
              percentText: '${levelPakanPersen.toStringAsFixed(1)}%',
              progress: (levelPakanPersen / 100).clamp(0.0, 1.0),
              color: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 10),
            _buildSensorValueCard(
              title: 'Sensor pH Air',
              statusText: (double.tryParse(phAir) ?? 0) >= 6.5 && (double.tryParse(phAir) ?? 0) <= 8.5 ? 'Normal' : 'Peringatan',
              valueText: phAir,
              unitText: 'pH',
              subtitle: 'Ideal: 6.5 - 8.5',
            ),
            const SizedBox(height: 10),
            _buildLevelWithBarCard(
              title: 'Level Air (Ultrasonik)',
              // Batas peringatan diubah ke 20%
              statusText: levelAirPersen > 20.0 ? 'Normal' : 'Peringatan', 
              percentText: '${levelAirPersen.toStringAsFixed(1)}%',
              progress: (levelAirPersen / 100).clamp(0.0, 1.0),
              color: const Color(0xFF0EA5E9),
            ),
          ],
          
          const SizedBox(height: 20),
          const Text(
            'Deteksi AI & Pemberian Pakan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          // const SizedBox(height: 12),
          // _buildAiMonitoringCard(),
          
          const SizedBox(height: 20),
          const Text(
            'History Pemberian Pakan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onBukaHistoryPakan,
              icon: const Icon(Icons.history),
              label: const Text('Lihat History Pemberian Pakan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
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
              Text('Smart Poultry Feeder', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Sistem Pakan Otomatis', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          IconButton(
            onPressed: widget.onBukaHalamanNotifikasi,
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValueCard({required String title, required String statusText, required String valueText, required String unitText, String? subtitle}) {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              _statusChip(statusText),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(valueText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text(unitText, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelWithBarCard({required String title, required String statusText, required String percentText, required double progress, required Color color}) {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              _statusChip(statusText, color: statusText == 'Normal' ? const Color(0xFF16A34A) : Colors.red),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress, 
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(percentText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildAiMonitoringCard() {
  //   return _baseCard(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Text('Status Deteksi AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
  //             Chip(
  //               backgroundColor: isAyamTerdeteksi ? const Color(0xFFD1FAE5) : Colors.red.shade50,
  //               label: Text(
  //                 pesanAi, // Dinamis dari API
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.w500,
  //                   color: isAyamTerdeteksi ? const Color(0xFF16A34A) : Colors.red,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             const Icon(Icons.access_time, size: 18, color: Colors.grey),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Deteksi terakhir: $waktuAi', // Dinamis dari API
  //               style: const TextStyle(fontSize: 13, color: Colors.grey),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _baseCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _statusChip(String text, {Color color = const Color(0xFF16A34A)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: text == 'Normal' ? color.withOpacity(0.08) : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            text == 'Normal' ? Icons.check_circle_outline : Icons.warning_amber_rounded, 
            size: 14, 
            color: text == 'Normal' ? color : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: text == 'Normal' ? color : Colors.red),
          ),
        ],
      ),
    );
  }
}