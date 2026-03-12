import 'package:flutter/material.dart';

class HalamanNotifikasi extends StatelessWidget {
  final String? selectedNotificationId;
  final void Function(String id) onNotificationTap;
  final VoidCallback onBack;

  const HalamanNotifikasi({
    super.key,
    required this.selectedNotificationId,
    required this.onNotificationTap,
    required this.onBack,
  });

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
            'Daftar Notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _notifikasiTile(
            id: 'auto_feed',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF16A34A),
            title: 'Pakan otomatis berhasil diberikan',
            subtitle: 'Hari ini, 14.30 • Porsi 500g',
          ),
          const SizedBox(height: 8),
          _notifikasiTile(
            id: 'low_water',
            icon: Icons.warning_amber_outlined,
            iconColor: const Color(0xFFF97316),
            title: 'Level air hampir habis - segera isi ulang',
            subtitle: 'Hari ini, 13.10 • Sisa 18% penyimpanan air',
          ),
          const SizedBox(height: 8),
          _notifikasiTile(
            id: 'ai_24',
            icon: Icons.visibility_outlined,
            iconColor: const Color(0xFF0EA5E9),
            title: 'Deteksi AI aktif - 24 ayam terdeteksi',
            subtitle: 'Hari ini, 12.00',
          ),
          const SizedBox(height: 20),
          const Text(
            'Detail Notifikasi & Log Deteksi AI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedNotificationId == 'ai_24') ...[
            _buildAiLogCard(
              time: 'Hari ini, 12.00',
              description: 'AI mendeteksi 24 ayam di area kandang utama.',
              prediction: 'Prediksi: Kepadatan normal, pakan cukup.',
            ),
            const SizedBox(height: 10),
            _buildAiLogCard(
              time: 'Hari ini, 08.00',
              description: 'AI mendeteksi 20 ayam saat pemberian pakan pagi.',
              prediction: 'Prediksi: Konsumsi pakan stabil.',
            ),
          ] else
            _baseCard(
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih notifikasi deteksi AI untuk melihat detail foto dan prediksi.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Text(
            'History Notifikasi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifikasiTile({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedNotificationId == id;

    return InkWell(
      onTap: () => onNotificationTap(id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF0EA5E9), width: 1)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiLogCard({
    required String time,
    required String description,
    required String prediction,
  }) {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Pratinjau foto AI\n(placeholder)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(
                Icons.psychology_outlined,
                size: 18,
                color: Color(0xFF16A34A),
              ),
              SizedBox(width: 6),
              Text(
                'Prediksi AI:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            prediction,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
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

