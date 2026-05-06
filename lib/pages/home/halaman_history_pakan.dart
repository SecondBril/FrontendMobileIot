// lib/pages/history/halaman_history_pakan.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_ui_challenge/service/api_refresh_service.dart';
import 'package:iot_ui_challenge/pages/home/widgets/shared_widgets.dart';
import '../../service/history_api.dart';

class HalamanHistoryPakan extends StatefulWidget {
  final VoidCallback onBack;

  const HalamanHistoryPakan({
    super.key,
    required this.onBack,
  });

  @override
  State<HalamanHistoryPakan> createState() => _HalamanHistoryPakanState();
}

class _HalamanHistoryPakanState extends State<HalamanHistoryPakan>
    with WidgetsBindingObserver {
  late final ApiRefreshService _svc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _svc = context.read<ApiRefreshService>();
    _svc.start(RefreshEndpoint.historyPakan);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _svc.pause(RefreshEndpoint.historyPakan);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _svc.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      _svc.start(RefreshEndpoint.historyPakan);
    }
  }

  String _formatDateLabel(String dateStr) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (dateStr == todayStr) return 'Hari Ini';
    if (dateStr == yesterdayStr) return 'Kemarin';
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    // Satu sumber data — dari ApiRefreshService
    final state = context.watch<ApiRefreshService>().historyState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildTopBar(),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'History Pemberian Pakan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),

        // ── Indikator waktu update terakhir ──────────────────────────────────
        if (state.lastUpdated != null)
          LastUpdatedBar(time: state.lastUpdated!),

        // ── Banner error ringan (data lama masih ditampilkan) ────────────────
        if (state.errorMessage != null)
          ErrorBanner(
            message: state.errorMessage!,
            onRetry: () =>
                context.read<ApiRefreshService>().forceRefresh(RefreshEndpoint.historyPakan),
          ),

        const SizedBox(height: 8),

        // ── Body ─────────────────────────────────────────────────────────────
        Expanded(child: _buildBody(state)),
      ],
    );
  }

  Widget _buildBody(RefreshState<List<dynamic>> state) {
    // Masih loading pertama kali (belum ada data sama sekali)
    if (state.isLoading && state.data == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      );
    }

    // Gagal total (tidak ada data sama sekali)
    if (state.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.errorMessage ?? 'Gagal memuat data'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context
                  .read<ApiRefreshService>()
                  .forceRefresh(RefreshEndpoint.historyPakan),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final logs = state.data!;

    if (logs.isEmpty) {
      return const Center(child: Text('Belum ada riwayat pemberian pakan.'));
    }

    // Bangun widget list dengan header tanggal
    final List<Widget> historyWidgets = [];
    String? lastDate;

    for (final log in logs) {
      final dateStr = log['tanggal'] as String;

      if (dateStr != lastDate) {
        historyWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              _formatDateLabel(dateStr),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
        );
        lastDate = dateStr;
      }

      final isSkipped = log['status_eksekusi'] == 'DILEWATI' ||
          log['status_eksekusi'] == 'GAGAL';
      final infoJadwal = log['info_jadwal_master'];
      final porsiGram = infoJadwal != null
          ? infoJadwal['porsi_master_gram']
          : log['porsi_gram_target'];

      String detailText = 'Porsi ${porsiGram}g • ${log['mode']}';
      if (log['slot_jadwal'] != null) {
        detailText += ' (${log['slot_jadwal']})';
      }
      if (log['keterangan_sistem'] != null &&
          log['keterangan_sistem'].toString().isNotEmpty) {
        detailText = '${log['keterangan_sistem']} - $detailText';
      }

      historyWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _eventTile(
            context: context,
            title: log['judul'] ?? 'Tidak diketahui',
            time: log['waktu'] ?? '',
            detail: detailText,
            isSkipped: isSkipped,
            detailKandang: log['detail_kandang'] ?? [],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: historyWidgets.length,
      itemBuilder: (_, i) => historyWidgets[i],
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

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
            onPressed: widget.onBack,
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
    required List<dynamic> detailKandang,
    bool isSkipped = false,
  }) {
    final color =
        isSkipped ? const Color(0xFF9CA3AF) : const Color(0xFF16A34A);
    final icon =
        isSkipped ? Icons.cancel_outlined : Icons.check_circle_outline;
    final bool isDisabled = detailKandang.isEmpty;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isDisabled
                ? null
                : () => _showDetailPakanSheet(
                      context,
                      title: title,
                      time: time,
                      detail: detail,
                      kandangList: detailKandang,
                    ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(time,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(detail,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87)),
                        if (!isDisabled) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  size: 14, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text(
                                'Lihat detail & foto ayam',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailPakanSheet(
    BuildContext context, {
    required String title,
    required String time,
    required String detail,
    required List<dynamic> kandangList,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(time,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(detail,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 16),
                  const Text('Foto ayam & pakan per kandang',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: kandangList.length,
                    itemBuilder: (context, index) {
                      final kandang = kandangList[index];
                      final urlAyam = HistoryApi.getFullImageUrl(
                          kandang['foto_ayam'] ?? '');
                      final urlPakan = HistoryApi.getFullImageUrl(
                          kandang['foto_pakan'] ?? '');
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
                                    top: Radius.circular(12)),
                                child: _DualPhotoSlider(
                                  chickenUrl: urlAyam,
                                  feedUrl: urlPakan,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                kandang['nama_kandang'] ?? 'Kandang ?',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
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

  const _DualPhotoSlider({required this.chickenUrl, required this.feedUrl});

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
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(p.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_index + 1}/${pages.length}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}