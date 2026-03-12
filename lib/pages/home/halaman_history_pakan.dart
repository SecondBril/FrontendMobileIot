import 'package:flutter/material.dart';

class HalamanHistoryPakan extends StatelessWidget {
  final VoidCallback onBack;

  const HalamanHistoryPakan({
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
          const Text(
            'History Pemberian Pakan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _eventTile(
            context: context,
            title: 'Pakan otomatis berhasil diberikan',
            time: 'Hari ini, 14.30',
            detail: 'Porsi 500g • Mode Otomatis',
          ),
          const SizedBox(height: 8),
          _eventTile(
            context: context,
            title: 'Pakan manual berhasil diberikan',
            time: 'Hari ini, 10.15',
            detail: 'Porsi 400g • Tombol manual',
          ),
          const SizedBox(height: 8),
          _eventTile(
            context: context,
            title: 'Jadwal pakan otomatis berhasil',
            time: 'Hari ini, 06.00',
            detail: 'Porsi 500g • Slot jadwal 06:00',
          ),
          const SizedBox(height: 8),
          _eventTile(
            context: context,
            title: 'Pemberian pakan dilewati - tidak ada ayam terdeteksi',
            time: 'Hari ini, 02.45',
            detail: 'AI tidak mendeteksi ayam di area makan',
            isSkipped: true,
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
            'History Pemberian Pakan',
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

  Widget _eventTile({
    required BuildContext context,
    required String title,
    required String time,
    required String detail,
    bool isSkipped = false,
  }) {
    final color = isSkipped ? const Color(0xFF9CA3AF) : const Color(0xFF16A34A);
    final icon =
        isSkipped ? Icons.cancel_outlined : Icons.check_circle_outline;

    return InkWell(
      onTap: isSkipped
          ? null
          : () {
              _showDetailPakanSheet(
                context,
                title: title,
                time: time,
                detail: detail,
              );
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
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
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                  if (!isSkipped) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Lihat detail & foto ayam',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailPakanSheet(
    BuildContext context, {
    required String title,
    required String time,
    required String detail,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final kandangList = [
          {
            'name': 'Kandang 1',
            'chickenImage':
                'https://images.pexels.com/photos/4911709/pexels-photo-4911709.jpeg?auto=compress&cs=tinysrgb&w=600',
            'feedImage':
                'https://images.pexels.com/photos/6646357/pexels-photo-6646357.jpeg?auto=compress&cs=tinysrgb&w=600',
          },
          {
            'name': 'Kandang 2',
            'chickenImage':
                'https://images.pexels.com/photos/4911708/pexels-photo-4911708.jpeg?auto=compress&cs=tinysrgb&w=600',
            'feedImage':
                'https://images.pexels.com/photos/6646360/pexels-photo-6646360.jpeg?auto=compress&cs=tinysrgb&w=600',
          },
          {
            'name': 'Kandang 3',
            'chickenImage':
                'https://images.pexels.com/photos/4911745/pexels-photo-4911745.jpeg?auto=compress&cs=tinysrgb&w=600',
            'feedImage':
                'https://images.pexels.com/photos/6646358/pexels-photo-6646358.jpeg?auto=compress&cs=tinysrgb&w=600',
          },
        ];

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Foto ayam & pakan per kandang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: kandangList.length,
                    itemBuilder: (context, index) {
                      final kandang = kandangList[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: _DualPhotoSlider(
                                  chickenUrl: kandang['chickenImage'] as String,
                                  feedUrl: kandang['feedImage'] as String,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                kandang['name'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DualPhotoSlider extends StatefulWidget {
  final String chickenUrl;
  final String feedUrl;

  const _DualPhotoSlider({
    required this.chickenUrl,
    required this.feedUrl,
  });

  @override
  State<_DualPhotoSlider> createState() => _DualPhotoSliderState();
}

class _DualPhotoSliderState extends State<_DualPhotoSlider> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      (label: 'Ayam', url: widget.chickenUrl),
      (label: 'Pakan', url: widget.feedUrl),
    ];

    return Stack(
      children: [
        PageView.builder(
          itemCount: pages.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final p = pages[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  p.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      p.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_index + 1}/${pages.length}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

