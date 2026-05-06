import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';

// Model untuk data per kandang
class KandangData {
  final TextEditingController idController;
  File? imageCam1;
  File? imageCam2;

  KandangData({required String defaultId})
      : idController = TextEditingController(text: defaultId);

  void dispose() {
    idController.dispose();
  }
}

class ManualTelemetryPage extends StatefulWidget {
  const ManualTelemetryPage({Key? key}) : super(key: key);

  @override
  _ManualTelemetryPageState createState() => _ManualTelemetryPageState();
}

class _ManualTelemetryPageState extends State<ManualTelemetryPage>
    with SingleTickerProviderStateMixin {
  // 3 kandang data
  late final List<KandangData> _kandangList;

  bool _isLoading = false;
  String _resultLog = "";
  int _successCount = 0;
  int _failCount = 0;

  final ImagePicker _picker = ImagePicker();
  final String _apiUrl = "${ApiConfig.baseUrl}/api/telemetri_visual";

  // Tab controller untuk navigasi antar kandang
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _kandangList = [
      KandangData(defaultId: "KANDANG_01"),
      KandangData(defaultId: "KANDANG_02"),
      KandangData(defaultId: "KANDANG_03"),
    ];
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    for (final k in _kandangList) {
      k.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int kandangIndex, int camNumber) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (camNumber == 1) {
          _kandangList[kandangIndex].imageCam1 = File(pickedFile.path);
        } else {
          _kandangList[kandangIndex].imageCam2 = File(pickedFile.path);
        }
      });
    }
  }

  // Validasi semua kandang sebelum submit
  List<int> _getKandangWithMissingImages() {
    List<int> missing = [];
    for (int i = 0; i < _kandangList.length; i++) {
      final k = _kandangList[i];
      if (k.imageCam1 == null || k.imageCam2 == null) {
        missing.add(i + 1);
      }
    }
    return missing;
  }

  Future<void> _uploadAllKandang() async {
    final missingKandang = _getKandangWithMissingImages();
    if (missingKandang.isNotEmpty) {
      final namaKandang = missingKandang.map((i) => "Kandang $i").join(", ");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Gambar CAM_1 & CAM_2 wajib diisi untuk: $namaKandang"),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultLog = "=== MEMULAI PROSES UPLOAD 3 KANDANG ===\n\n";
      _successCount = 0;
      _failCount = 0;
    });

    // Kirim semua kandang secara sekuensial
    for (int i = 0; i < _kandangList.length; i++) {
      final kandang = _kandangList[i];
      final kandangLabel = "KANDANG ${i + 1} (${kandang.idController.text})";

      setState(() => _resultLog += "--- $kandangLabel ---\n");

      try {
        // CAM 1
        setState(() => _resultLog += "  ▶ Mengirim CAM_1...\n");
        var response1 =
            await _sendMultipartRequest(kandang.idController.text, "CAM_1", kandang.imageCam1!);
        var json1 = jsonDecode(response1);
        if (json1['status'] != 'success') {
          throw Exception("Gagal CAM_1: ${json1['detail']}");
        }
        setState(() => _resultLog += "  ✓ CAM_1 sukses.\n");

        // CAM 2
        setState(() => _resultLog += "  ▶ Mengirim CAM_2...\n");
        var response2 =
            await _sendMultipartRequest(kandang.idController.text, "CAM_2", kandang.imageCam2!);
        var json2 = jsonDecode(response2);
        if (json2['status'] != 'success') {
          throw Exception("Gagal CAM_2: ${json2['detail']}");
        }

        final keputusan = json2['analisis_agregat']['keputusan_robot'] ?? '-';
        final alasan = json2['analisis_agregat']['alasan'] ?? '-';

        setState(() {
          _resultLog += "  ✓ CAM_2 sukses.\n";
          _resultLog += "  🤖 Keputusan: $keputusan\n";
          _resultLog += "  📋 Alasan: $alasan\n\n";
          _successCount++;
        });
      } catch (e) {
        setState(() {
          _resultLog += "  ❌ ERROR: $e\n\n";
          _failCount++;
        });
      }
    }

    setState(() {
      _resultLog +=
          "=== SELESAI: $_successCount Sukses | $_failCount Gagal ===";
      _isLoading = false;
    });
  }

  Future<String> _sendMultipartRequest(
      String deviceId, String posisiCam, File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.fields['device_id'] = deviceId;
    request.fields['jadwal'] = "MANUAL";
    request.fields['posisi_cam'] = posisiCam;
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 400) {
      throw Exception("HTTP Error ${response.statusCode}: ${response.body}");
    }
    return response.body;
  }

  // Ringkasan status gambar per kandang (untuk tab badge)
  String _getKandangStatus(int index) {
    final k = _kandangList[index];
    final cam1 = k.imageCam1 != null ? "✓" : "✗";
    final cam2 = k.imageCam2 != null ? "✓" : "✗";
    return "C1:$cam1 C2:$cam2";
  }

  bool _isKandangComplete(int index) {
    final k = _kandangList[index];
    return k.imageCam1 != null && k.imageCam2 != null;
  }

  @override
  Widget build(BuildContext context) {
    final allComplete =
        _kandangList.every((k) => k.imageCam1 != null && k.imageCam2 != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Debugger Telemetri AI"),
        backgroundColor: Colors.red[800],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: List.generate(3, (i) {
            final complete = _isKandangComplete(i);
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    complete ? Icons.check_circle : Icons.circle_outlined,
                    size: 14,
                    color: complete ? Colors.greenAccent : Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Kandang ${i + 1}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgressBar(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (i) => _buildKandangTab(i)),
            ),
          ),

          // Tombol submit + log
          _buildBottomSection(allComplete),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final filled = _kandangList.where((k) => k.imageCam1 != null && k.imageCam2 != null).length;
    return Container(
      color: Colors.red[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            "Progress Foto: $filled/3 Kandang",
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[900],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: filled / 3,
                backgroundColor: Colors.red[100],
                valueColor: AlwaysStoppedAnimation<Color>(
                    filled == 3 ? Colors.green : Colors.red[700]!),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKandangTab(int index) {
    final kandang = _kandangList[index];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kandang ID Field
          TextField(
            controller: kandang.idController,
            decoration: InputDecoration(
              labelText: "ID Kandang ${index + 1}",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.warehouse_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Label
          Text(
            "Upload Foto Kandang ${index + 1}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),

          // Image selectors side by side
          Row(
            children: [
              Expanded(
                child: _buildImageSelector(
                  index,
                  1,
                  "🐔 Foto Ayam\n(CAM 1)",
                  kandang.imageCam1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildImageSelector(
                  index,
                  2,
                  "🌾 Foto Pakan\n(CAM 2)",
                  kandang.imageCam2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status chip
          Center(
            child: Chip(
              avatar: Icon(
                _isKandangComplete(index) ? Icons.check_circle : Icons.pending,
                color: _isKandangComplete(index) ? Colors.green : Colors.orange,
                size: 18,
              ),
              label: Text(
                _isKandangComplete(index)
                    ? "Kandang ${index + 1} siap dikirim"
                    : "Belum lengkap (${_getKandangStatus(index)})",
                style: TextStyle(
                  color: _isKandangComplete(index)
                      ? Colors.green[800]
                      : Colors.orange[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _isKandangComplete(index)
                  ? Colors.green[50]
                  : Colors.orange[50],
            ),
          ),

          // Navigasi antar tab
          if (index < 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => _tabController.animateTo(index + 1),
                icon: const Icon(Icons.arrow_forward),
                label: Text("Lanjut ke Kandang ${index + 2}"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSelector(
      int kandangIndex, int camNumber, String title, File? image) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isLoading ? null : () => _pickImage(kandangIndex, camNumber),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: image != null ? Colors.green : Colors.grey,
                width: image != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: image != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.file(image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => setState(() {
                                    if (camNumber == 1) {
                                      _kandangList[kandangIndex].imageCam1 =
                                          null;
                                    } else {
                                      _kandangList[kandangIndex].imageCam2 =
                                          null;
                                    }
                                  }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 36, color: Colors.grey),
                      SizedBox(height: 6),
                      Text("Tap untuk pilih",
                          style:
                              TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool allComplete) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Submit button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _uploadAllKandang,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(
              _isLoading
                  ? "Mengirim Data..."
                  : "Eksekusi Simulasi AI (3 Kandang)",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: allComplete ? Colors.red[800] : Colors.grey[400],
            ),
          ),

          // Log section
          if (_resultLog.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Log Sistem:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (!_isLoading)
                  TextButton(
                    onPressed: () => setState(() => _resultLog = ""),
                    child: const Text("Clear",
                        style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _resultLog,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
