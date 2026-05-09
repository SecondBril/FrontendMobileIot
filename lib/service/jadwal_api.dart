import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class JadwalApiService {
  // 1. READ: Ambil semua jadwal
  static Future<List<dynamic>> fetchJadwal() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/jadwal/${ApiConfig.deviceId}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal mengambil data jadwal');
      }
    } catch (e) {
      throw Exception('Error koneksi: $e');
    }
  }

  // 2. CREATE: Tambah jadwal baru
  static Future<bool> createJadwal(String waktu, int porsi) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/jadwal');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'device_id': ApiConfig.deviceId,
          'waktu': waktu,
          'porsi_gram': porsi,
        }),
      );
      if (response.statusCode == 200) return true;
      print('GAGAL POST [HTTP ${response.statusCode}]: ${response.body}');
      return false;
    } catch (e) {
      print('ERROR KONEKSI FATAL: $e');
      return false;
    }
  }

  // 3. EDIT: Ubah waktu + porsi jadwal yang sudah ada
  static Future<bool> editJadwal(int jadwalId, String waktu, int porsi) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/jadwal/$jadwalId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'waktu': waktu,
          'porsi_gram': porsi,
        }),
      );
      if (response.statusCode == 200) return true;
      print('GAGAL PUT [HTTP ${response.statusCode}]: ${response.body}');
      return false;
    } catch (e) {
      print('ERROR EDIT JADWAL: $e');
      return false;
    }
  }

  // 4. UPDATE: Toggle Aktif/Tidak Aktif
  static Future<bool> toggleJadwal(int jadwalId, bool isActive) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/jadwal/$jadwalId/toggle');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_active': isActive}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. DELETE: Hapus jadwal
  static Future<bool> deleteJadwal(int jadwalId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/jadwal/$jadwalId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
