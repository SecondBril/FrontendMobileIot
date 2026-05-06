import 'package:flutter/material.dart';
import 'dart:async';
import '../service/monitoring_api.dart';

class SensorProvider extends ChangeNotifier {
  Timer? _timer;
  bool isLoading = true;

  // Data State
  String phAir = '0.0';
  double levelPakanPersen = 0.0;
  double levelAirPersen = 0.0;
  double beratPakanKg = 0.0;
  bool isAyamTerdeteksi = false;
  String pesanAi = 'Menunggu data...';
  String waktuAi = '-';

  SensorProvider() {
    _mulaiPolling();
  }

  void _mulaiPolling() {
    fetchData(); // Ambil langsung saat inisialisasi
    // Catatan: Tetap ganti ke MQTT/WebSocket kelak. Ini hanya menambal kebocoran request ganda.
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    final data = await MonitoringApiService.fetchLatestData();
    
    if (data != null) {
      phAir = data['ph_value']?.toString() ?? '0.0';
      levelPakanPersen = (data['pakan_level_persen'] ?? 0).toDouble();
      levelAirPersen = (data['air_level_persen'] ?? 0).toDouble();
      beratPakanKg = (data['berat_loadcell_kg'] ?? 0.0).toDouble();
      isAyamTerdeteksi = data['ayam_terdeteksi'] ?? false;
      pesanAi = data['pesan_ai'] ?? (isAyamTerdeteksi ? 'Ayam terdeteksi' : 'Kandang kosong');
      waktuAi = data['waktu_deteksi_ai'] ?? 'Baru saja';
      isLoading = false;
      
      // Memberitahu semua halaman yang mendengarkan bahwa data telah berubah
      notifyListeners();
    } else if (isLoading) {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}