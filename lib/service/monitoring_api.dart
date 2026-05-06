import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MonitoringApiService {
  static Future<Map<String, dynamic>?> fetchLatestData() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/sensor/latest');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; 
        }
      }
      return null; 
    } catch (e) {
      // Peringatan: Di production, kirim error ini ke Crashlytics atau Sentry.
      print('Error Fetch Monitoring: $e');
      return null; 
    }
  }
}