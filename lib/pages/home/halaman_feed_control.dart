import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final List<Map<String, dynamic>> _feedingSlots = [
    {'time': '06:00', 'portion': '500', 'enabled': true},
    {'time': '12:00', 'portion': '600', 'enabled': true},
    {'time': '18:00', 'portion': '500', 'enabled': true},
    {'time': '21:00', 'portion': '400', 'enabled': false},
  ];

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
          _buildAutomaticFeedingCard(),
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
            'Feeding Control',
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

  Widget _buildCurrentStatusCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.analytics_outlined, size: 18, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text(
                'Status Saat Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mode Sistem', style: TextStyle(fontSize: 13)),
              Text(
                _enableAutoFeeding ? 'Otomatis' : 'Manual',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text('Hari ini, 08:00',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              '2 jam yang lalu • Porsi 500g',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticFeedingCard() {
    final activeCount = _feedingSlots.where((s) => s['enabled'] == true).length;

    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text(
                'Pakan Otomatis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
          ..._feedingSlots.asMap().entries.map((entry) {
            final i = entry.key;
            final slot = entry.value;
            final enabled = slot['enabled'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFFD1FAE5).withOpacity(0.5)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '${slot['time']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${slot['portion']}g',
                      style: TextStyle(
                        fontSize: 13,
                        color: enabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 22, color: Colors.red[400]),
                      onPressed: () {
                        setState(() {
                          _feedingSlots.removeAt(i);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    Switch(
                      value: enabled,
                      onChanged: (v) => setState(() {
                        _feedingSlots[i]['enabled'] = v;
                      }),
                      activeColor: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showAddSlotDialog,
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

  Future<void> _showAddSlotDialog() async {
    TimeOfDay selectedTime = const TimeOfDay(hour: 12, minute: 0);
    final portionController = TextEditingController(text: '500');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Slot Waktu Baru'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waktu',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Icon(Icons.access_time, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Porsi (g)',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: portionController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '100 - 1000',
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
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final portion = portionController.text.trim();
                    if (portion.isEmpty) return;
                    final p = int.tryParse(portion) ?? 500;
                    if (p < 100 || p > 1000) return;
                    final timeStr =
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                    Navigator.of(context)
                        .pop({'time': timeStr, 'portion': portion});
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A)),
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );

    portionController.dispose();

    if (result != null && mounted) {
      setState(() {
        _feedingSlots.add({
          'time': result['time'] ?? '12:00',
          'portion': result['portion'] ?? '500',
          'enabled': true,
        });
      });
    }
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

