import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';


class ManualTelemetryPage extends StatefulWidget {
  const ManualTelemetryPage({Key? key}) : super(key: key);

  @override
  _ManualTelemetryPageState createState() => _ManualTelemetryPageState();
}

class _ManualTelemetryPageState extends State<ManualTelemetryPage> {
  final _kandangIdController = TextEditingController(text: "KANDANG_01");
  File? _imageCam1;
  File? _imageCam2;
  bool _isLoading = false;
  String _resultLog = "";

  final ImagePicker _picker = ImagePicker();
  
  // Ganti dengan IP Local Backend Anda (Gunakan IP komputer jika di emulator/device fisik)
  final String _apiUrl = "${ApiConfig.baseUrl}/api/telemetri_visual"; 

  Future<void> _pickImage(int camNumber) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (camNumber == 1) _imageCam1 = File(pickedFile.path);
        else _imageCam2 = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadManualTelemetry() async {
    if (_imageCam1 == null || _imageCam2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gambar CAM_1 dan CAM_2 wajib diisi!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultLog = "Memulai proses unggah...\n";
    });

    try {
      // 1. Eksekusi CAM 1 (Ayam)
      setState(() => _resultLog += "Mengirim Data CAM_1...\n");
      var response1 = await _sendMultipartRequest("CAM_1", _imageCam1!);
      var json1 = jsonDecode(response1);
      
      if (json1['status'] != 'success') throw Exception("Gagal di CAM_1: ${json1['detail']}");
      
      setState(() => _resultLog += "Sukses CAM_1. Menunggu penjahitan...\n\nMengirim Data CAM_2...\n");

      // 2. Eksekusi CAM 2 (Pakan) secara Sekuensial
      var response2 = await _sendMultipartRequest("CAM_2", _imageCam2!);
      var json2 = jsonDecode(response2);

      if (json2['status'] != 'success') throw Exception("Gagal di CAM_2: ${json2['detail']}");

      setState(() {
        _resultLog += "Sukses CAM_2. Penjahitan Selesai.\n\n";
        _resultLog += "Keputusan Robot: ${json2['analisis_agregat']['keputusan_robot']}\n";
        _resultLog += "Alasan: ${json2['analisis_agregat']['alasan']}";
      });

    } catch (e) {
      setState(() => _resultLog += "\nERROR: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _sendMultipartRequest(String posisiCam, File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    
    // Parameter Wajib Backend
    request.fields['device_id'] = _kandangIdController.text;
    request.fields['jadwal'] = "MANUAL"; 
    request.fields['posisi_cam'] = posisiCam;
    
    // BENAR: Menyatakan secara eksplisit bahwa ini adalah gambar
    request.files.add(await http.MultipartFile.fromPath(
      'file', 
      imageFile.path,
      contentType: MediaType('image', 'jpeg'), // Pastikan package http_parser sudah di-import
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 400) {
      throw Exception("HTTP Error ${response.statusCode}: ${response.body}");
    }
    
    return response.body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Debugger Telemetri AI"),
        backgroundColor: Colors.red[800], // Warna merah sebagai peringatan ini mode debug
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _kandangIdController,
              decoration: const InputDecoration(
                labelText: "Kandang ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSelector(1, "Foto Ayam (CAM 1)", _imageCam1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSelector(2, "Foto Pakan (CAM 2)", _imageCam2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadManualTelemetry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Eksekusi Simulasi AI", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            const Text("Log Sistem:", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 150),
              color: Colors.grey[200],
              width: double.infinity,
              child: Text(_resultLog, style: const TextStyle(fontFamily: 'monospace')),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector(int camIndex, String title, File? image) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickImage(camIndex),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}