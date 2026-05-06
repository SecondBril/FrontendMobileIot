import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

enum NotifType { sukses, dilewati, parsial, anomali, kesimpulan, info }

class NotifItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final NotifType type;
  final String? deviceId;
  final String? analisisAi;
  final String? urlCam1;
  final String? urlCam2;
  final String? ringkasan;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.deviceId,
    this.analisisAi,
    this.urlCam1,
    this.urlCam2,
    this.ringkasan,
  });

  /// Kunci deduplication: type + deviceId + body (tanpa timestamp)
  String get dedupKey =>
      '${type.name}|${deviceId ?? ""}|${body.substring(0, body.length.clamp(0, 80))}';
}

class NotificationProvider extends ChangeNotifier {
  final List<NotifItem> _items = [];

  // Set kunci notif yang sudah masuk dalam 60 detik terakhir
  final Map<String, DateTime> _recentKeys = {};

  List<NotifItem> get items => List.unmodifiable(_items);

  void addMessage(RemoteMessage message) {
    Future.microtask(() {
      final data = message.data;
      final title = data['title'] as String?
          ?? message.notification?.title
          ?? 'Notifikasi Sistem';
      final body = data['body'] as String?
          ?? message.notification?.body
          ?? '';

      final payloadType = data['type'] as String?;
      final type = _resolveType(title, payloadType);

      // ← Baca URL, bukan base64
      final urlCam1 = data['url_cam1'] as String?;
      final urlCam2 = data['url_cam2'] as String?;

      final notif = NotifItem(
        id: message.messageId
            ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        time: DateTime.now(),
        type: type,
        deviceId: data['device_id'] as String?,
        analisisAi: data['analisis_ai'] as String?,
        urlCam1: (urlCam1?.isNotEmpty == true) ? urlCam1 : null,
        urlCam2: (urlCam2?.isNotEmpty == true) ? urlCam2 : null,
        ringkasan: data['ringkasan'] as String?,
      );

      _bersihkanKunciLama();
      if (_recentKeys.containsKey(notif.dedupKey)) {
        debugPrint('[Notif] Duplikat diabaikan: ${notif.dedupKey}');
        return;
      }
      _recentKeys[notif.dedupKey] = DateTime.now();

      _items.insert(0, notif);
      notifyListeners();
    });
  }
  /// Hapus kunci yang sudah lebih dari 60 detik
  void _bersihkanKunciLama() {
    final batas = DateTime.now().subtract(const Duration(seconds: 60));
    _recentKeys.removeWhere((_, t) => t.isBefore(batas));
  }

  NotifType _resolveType(String title, String? payloadType) {
    if (payloadType == 'ANOMALI') return NotifType.anomali;
    if (payloadType == 'KESIMPULAN_SIKLUS') return NotifType.kesimpulan;
    if (payloadType == 'SUKSES') return NotifType.sukses;
    if (title.contains('✅')) return NotifType.sukses;
    if (title.contains('❌')) return NotifType.dilewati;
    if (title.contains('⚠️')) return NotifType.anomali;
    if (title.contains('📋') || title.contains('🔴')) return NotifType.kesimpulan;
    return NotifType.info;
  }

  void clearAll() {
    _items.clear();
    _recentKeys.clear();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}