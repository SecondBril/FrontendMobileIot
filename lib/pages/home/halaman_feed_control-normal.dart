import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/jadwal_api.dart';

class HalamanFeedControl extends StatefulWidget {
  final VoidCallback onBukaHalamanNotifikasi;

  const HalamanFeedControl({
    super.key,
    required this.onBukaHalamanNotifikasi,
  });

  @override
  State<HalamanFeedControl> createState() => _HalamanFeedControlState();
}

class _HalamanFeedControlState extends State<HalamanFeedControl> {
  bool _enableAutoFeeding = true;
  bool _isLoading = true;
  List<dynamic> _feedingSlots = [];

  @override
  void initState() {
    super.initState();
    _loadDataJadwal();
  }

  Future<void> _loadDataJadwal() async {
    setState(() => _isLoading = true);
    try {
      final data = await JadwalApiService.fetchJadwal();
      setState(() {
        _feedingSlots = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat jadwal dari server.');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ================================================================
  //  DIALOG TAMBAH / EDIT — satu fungsi, dua mode
  //  editSlot = null → mode Tambah
  //  editSlot = {...} → mode Edit (pre-filled)
  // ================================================================
  Future<void> _showSlotDialog({Map<String, dynamic>? editSlot}) async {
    final isEdit = editSlot != null;

    // Nilai awal: pre-fill saat edit, default saat tambah
    TimeOfDay selectedTime = isEdit
        ? _parseWaktu(editSlot!['waktu'] as String)
        : const TimeOfDay(hour: 12, minute: 0);
    final portionController = TextEditingController(
      text: isEdit ? '${editSlot!['porsi_gram']}' : '500',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? 'Edit Jadwal Pakan' : 'Tambah Slot Waktu Baru',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Waktu ─────────────────────────────────────────
                  const Text('Waktu',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:'
                            '${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Icon(Icons.access_time, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Porsi ─────────────────────────────────────────
                  const Text('Porsi (gram)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: portionController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '10 - 9999',
                      suffixText: 'g',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final portion = portionController.text.trim();
                    if (portion.isEmpty) return;
                    final p = int.tryParse(portion) ?? 0;
                    if (p < 10 || p > 9999) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Porsi harus antara 10–9999 gram')),
                      );
                      return;
                    }
                    final timeStr =
                        '${selectedTime.hour.toString().padLeft(2, '0')}:'
                        '${selectedTime.minute.toString().padLeft(2, '0')}';
                    Navigator.of(context)
                        .pop({'time': timeStr, 'portion': portion});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isEdit ? 'Simpan' : 'Tambah',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    portionController.dispose();
    if (result == null || !mounted) return;

    final waktu = result['time']!;
    final porsi = int.parse(result['portion']!);

    setState(() => _isLoading = true);

    bool success;
    if (isEdit) {
      // ── Mode Edit: panggil PUT /api/jadwal/{id} ─────────────────
      success = await JadwalApiService.editJadwal(
          editSlot!['id'] as int, waktu, porsi);
      if (success) {
        _showSnackBar('Jadwal berhasil diperbarui');
      } else {
        _showSnackBar(
            'Gagal memperbarui jadwal. Cek koneksi atau jam duplikat.',
            isError: true);
      }
    } else {
      // ── Mode Tambah: panggil POST /api/jadwal ───────────────────
      success = await JadwalApiService.createJadwal(waktu, porsi);
      if (success) {
        _showSnackBar('Jadwal berhasil ditambahkan');
      } else {
        _showSnackBar(
            'Gagal menambahkan jadwal. Cek koneksi atau pastikan jam tidak duplikat.',
            isError: true);
      }
    }

    // Reload data apapun hasilnya agar state sinkron dengan server
    _loadDataJadwal();
  }

  // Helper: parse "HH:mm" → TimeOfDay
  TimeOfDay _parseWaktu(String waktu) {
    final parts = waktu.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
          _buildCurrentStatusCard(),
          const SizedBox(height: 12),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        color: Color(0xFF16A34A)),
                  ),
                )
              : _buildAutomaticFeedingCard(),
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
          const Text('Feeding Control',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          IconButton(
            onPressed: widget.onBukaHalamanNotifikasi,
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Status Saat Ini',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mode Sistem',
                  style: TextStyle(fontSize: 13)),
              Text(_enableAutoFeeding ? 'Otomatis' : 'Manual',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: const [
            Icon(Icons.access_time, size: 16, color: Colors.grey),
            SizedBox(width: 6),
            Text('Hari ini, 08:00',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text('2 jam yang lalu • Porsi 500g',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticFeedingCard() {
    final activeCount =
        _feedingSlots.where((s) => s['is_active'] == true).length;

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Pakan Otomatis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aktifkan Pakan Otomatis',
                  style: TextStyle(fontSize: 14)),
              Switch(
                value: _enableAutoFeeding,
                onChanged: (v) => setState(() => _enableAutoFeeding = v),
                activeColor: const Color(0xFF16A34A),
              ),
            ],
          ),
          Text('$activeCount slot aktif',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 12),

          // ── Daftar jadwal ───────────────────────────────────────
          ..._feedingSlots.asMap().entries.map((entry) {
            final slot    = entry.value;
            final jadwalId = slot['id'] as int;
            final enabled  = slot['is_active'] as bool;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFFD1FAE5).withOpacity(0.5)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: enabled
                        ? const Color(0xFF16A34A).withOpacity(0.2)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    // Waktu + porsi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${slot['waktu']}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: enabled
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${slot['porsi_gram']} gram',
                            style: TextStyle(
                              fontSize: 12,
                              color: enabled
                                  ? Colors.black54
                                  : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Tombol Edit ─────────────────────────────────
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 20, color: Colors.blue[400]),
                      tooltip: 'Edit jadwal',
                      onPressed: () => _showSlotDialog(editSlot: slot),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),

                    // ── Tombol Delete ───────────────────────────────
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red[400]),
                      tooltip: 'Hapus jadwal',
                      onPressed: () async {
                        final konfirmasi = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            title: const Text('Hapus Jadwal?'),
                            content: Text(
                              'Jadwal pukul ${slot['waktu']} (${slot['porsi_gram']}g) '
                              'akan dihapus permanen.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600]),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Hapus',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (konfirmasi == true) {
                          final ok =
                              await JadwalApiService.deleteJadwal(jadwalId);
                          if (ok) {
                            _showSnackBar('Jadwal dihapus');
                            _loadDataJadwal();
                          } else {
                            _showSnackBar('Gagal menghapus jadwal',
                                isError: true);
                          }
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),

                    // ── Toggle aktif ────────────────────────────────
                    Switch(
                      value: enabled,
                      onChanged: (v) async {
                        setState(() => slot['is_active'] = v);
                        final ok = await JadwalApiService.toggleJadwal(
                            jadwalId, v);
                        if (!ok) {
                          setState(() => slot['is_active'] = !v);
                          _showSnackBar('Gagal mengubah status jadwal',
                              isError: true);
                        }
                      },
                      activeColor: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // ── Tombol Tambah ───────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _showSlotDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Slot Waktu Baru'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF16A34A),
              side: const BorderSide(color: Color(0xFF16A34A)),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
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
