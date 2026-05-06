import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/notification_provider.dart';
import 'dart:typed_data';

class HalamanNotifikasi extends StatelessWidget {
  final VoidCallback onBack;

  const HalamanNotifikasi({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final logs = notifProvider.items;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Notifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (logs.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      context.read<NotificationProvider>().clearAll(),
                  child: const Text('Bersihkan',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Belum ada notifikasi baru hari ini.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final notif = logs[index];
                return _NotifTile(
                  notif: notif,
                  onDismiss: () =>
                      context.read<NotificationProvider>().removeItem(notif.id),
                );
              },
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
            'Kotak Masuk',
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
}

// ─── NOTIF TILE (expandable) ─────────────────────────────────────────────────

class _NotifTile extends StatefulWidget {
  final NotifItem notif;
  final VoidCallback onDismiss;

  const _NotifTile({required this.notif, required this.onDismiss});

  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile> {
  bool _expanded = false;

  // Pewarnaan pintar — sama seperti logika asli, ditambah tipe baru
  Color get _iconColor {
    switch (widget.notif.type) {
      case NotifType.anomali:
        return const Color(0xFFDC2626);
      case NotifType.parsial:
        return const Color(0xFFF97316);
      case NotifType.dilewati:
        return const Color(0xFF6B7280);
      case NotifType.kesimpulan:
        return const Color(0xFF7C3AED);
      case NotifType.sukses:
      default:
        return const Color(0xFF16A34A);
    }
  }

  IconData get _iconData {
    switch (widget.notif.type) {
      case NotifType.anomali:
        return Icons.warning_amber_outlined;
      case NotifType.parsial:
        return Icons.warning_amber_outlined;
      case NotifType.dilewati:
        return Icons.cancel_outlined;
      case NotifType.kesimpulan:
        return Icons.summarize_outlined;
      case NotifType.sukses:
      default:
        return Icons.check_circle_outline;
    }
  }

  String get _cleanTitle =>
      widget.notif.title.replaceAll(RegExp(r'[✅❌⚠️🔴📋]'), '').trim();

  String get _waktuStr {
    final t = widget.notif.time;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  bool get _hasDetail =>
      widget.notif.urlCam1 != null ||
      widget.notif.urlCam2 != null ||
      (widget.notif.analisisAi?.isNotEmpty == true) ||
      (widget.notif.ringkasan?.isNotEmpty == true);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: _hasDetail ? () => setState(() => _expanded = !_expanded) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Baris utama (sama persis dengan _notifikasiTile asli) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconData, size: 18, color: _iconColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris judul + waktu
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _cleanTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Chevron expand jika ada detail
                            if (_hasDetail)
                              AnimatedRotation(
                                turns: _expanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hari ini, $_waktuStr'
                          '${widget.notif.deviceId != null ? ' · ${widget.notif.deviceId}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.notif.body,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Panel detail (muncul saat expand) ───────────────────────
              if (_expanded && _hasDetail) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Foto dua kamera
                if (widget.notif.urlCam1 != null ||
                    widget.notif.urlCam2 != null) ...[
                  const _SectionLabel(text: 'FOTO KANDANG'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.notif.urlCam1 != null)
                        Expanded(
                          child: _FotoKamera(
                            data: widget.notif.urlCam1!,
                            label: 'Kamera 1',
                            accentColor: _iconColor,
                          ),
                        ),
                      if (widget.notif.urlCam1 != null &&
                          widget.notif.urlCam2 != null)
                        const SizedBox(width: 8),
                      if (widget.notif.urlCam2 != null)
                        Expanded(
                          child: _FotoKamera(
                            data: widget.notif.urlCam2!,
                            label: 'Kamera 2',
                            accentColor: _iconColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Analisis AI
                if (widget.notif.analisisAi?.isNotEmpty == true) ...[
                  const _SectionLabel(text: 'ANALISIS SISTEM'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _iconColor.withOpacity(0.15), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 13, color: _iconColor),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            widget.notif.analisisAi!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _iconColor,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Ringkasan semua kandang (untuk tipe kesimpulan)
                if (widget.notif.ringkasan?.isNotEmpty == true) ...[
                  const _SectionLabel(text: 'DETAIL KANDANG'),
                  const SizedBox(height: 6),
                  _RingkasanKandang(rawJson: widget.notif.ringkasan!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FOTO KAMERA ─────────────────────────────────────────────────────────────
// ─── FOTO KAMERA ─────────────────────────────────────────────────────────────
class _FotoKamera extends StatelessWidget {
  final String data;   // URL http://...
  final String label;
  final Color accentColor;

  const _FotoKamera({
    required this.data,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullscreenFotoUrl(url: data, label: label),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: data,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 120,
                color: Colors.grey.shade100,
                child: const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 120,
                color: Colors.grey.shade100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        color: Colors.grey.shade400, size: 28),
                    const SizedBox(height: 4),
                    Text('Gagal memuat',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      size: 11, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.open_in_full_rounded,
                      size: 11, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FULLSCREEN FOTO (URL) ────────────────────────────────────────────────────
class _FullscreenFotoUrl extends StatelessWidget {
  final String url;
  final String label;

  const _FullscreenFotoUrl({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}
// ─── RINGKASAN KANDANG ────────────────────────────────────────────────────────

class _RingkasanKandang extends StatelessWidget {
  final String rawJson;

  const _RingkasanKandang({required this.rawJson});

  /// Backend mengirim JSON string via json.dumps() — parse langsung
  List<Map<String, dynamic>> _parse() {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final kandangs = _parse();
    if (kandangs.isEmpty) return const SizedBox.shrink();

    return Column(
      children: kandangs.map((k) {
        final isAnomali = k['anomali'] == true || k['anomali'] == 'True';
        final keputusan = (k['keputusan'] ?? '').toString();
        final isSukses =
            keputusan == 'SUKSES' || keputusan == 'BUKA SERVO';
        final deviceId = (k['device_id'] ?? '-').toString();
        final detailAnomali = (k['detail_anomali'] ?? '').toString();

        final color = isAnomali
            ? const Color(0xFFDC2626)
            : (isSukses ? const Color(0xFF16A34A) : const Color(0xFF6B7280));
        final icon = isAnomali
            ? Icons.warning_amber_outlined
            : (isSukses
                ? Icons.check_circle_outline
                : Icons.cancel_outlined);

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.15), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceId,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                    if (detailAnomali.isNotEmpty &&
                        detailAnomali != 'null' &&
                        detailAnomali != 'None')
                      Text(
                        detailAnomali,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isAnomali
                      ? 'Anomali'
                      : (isSukses ? 'Diberi pakan' : 'Dilewati'),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.8,
      ),
    );
  }
}