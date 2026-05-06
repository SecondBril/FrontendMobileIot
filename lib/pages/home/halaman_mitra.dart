import 'package:flutter/material.dart';

class HalamanMitra extends StatelessWidget {
  final VoidCallback onBack;

  const HalamanMitra({
    super.key,
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
          _buildMitraProfileCard(),
          const SizedBox(height: 12),
          _buildAddressCard(),
          const SizedBox(height: 12),
          _buildHighlightsCard(),
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
            'Informasi Mitra',
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

  Widget _buildMitraProfileCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/BinaInsaniii.jpeg',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kelompok Tani Ternak Bina Insani',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mitra peternakan terpadu yang aktif mengembangkan budidaya sapi, domba, dan unggas (termasuk ayam) dengan pendekatan modern dan kolaboratif.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(
                Icons.person_outline,
                size: 18,
                color: Color(0xFF16A34A),
              ),
              SizedBox(width: 6),
              Text(
                'Ketua Mitra: Pak Rohimat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Alamat Mitra',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kelompok Tani Ternak Bina Insani\nKp. Cidogdog 20/06 Des. Wanasari, Kec. Cipunagara, Kab. Subang, Prov. Jawa Barat',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Profil Singkat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bina Insani menjadi mitra pengembangan Smart Poultry Feeder untuk meningkatkan efisiensi pemberian pakan, konsistensi pemantauan ternak, dan kualitas operasional kandang. Kolaborasi ini mendukung peternak lokal agar lebih siap menerapkan teknologi IoT dalam kegiatan harian.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.45,
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

