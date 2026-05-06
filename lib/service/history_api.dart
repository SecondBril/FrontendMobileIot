import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';


class HistoryApi {

  static Future<List<dynamic>> fetchHistoryPakan() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/history_pakan'));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data'];
        } else {
          throw Exception('API merespon, tetapi status data gagal.');
        }
      } else {
        throw Exception('Gagal menghubungi server. HTTP Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error Jaringan: $e');
    }
  }

  // Fungsi utilitas untuk merakit URL gambar secara utuh
  static String getFullImageUrl(String? partialPath) {
    if (partialPath == null || partialPath.isEmpty) return '';
    // Hapus slash di depan jika ada, agar tidak double slash
    final cleanPath = partialPath.startsWith('/') ? partialPath.substring(1) : partialPath;
    return '${ApiConfig.baseUrl}/$cleanPath';
  }
}