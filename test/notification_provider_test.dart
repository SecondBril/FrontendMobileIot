import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iot_ui_challenge/utils/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationProvider', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('adds a notification item from remote message payload', () async {
      final message = RemoteMessage(
        messageId: 'msg1',
        data: {
          'type': 'ANOMALI',
          'device_id': 'DEVICE_1',
          'title': '⚠️ Anomali',
          'body': 'Anomali terdeteksi',
          'analisis_ai': 'AI mendeteksi suhu tinggi',
          'url_cam1': 'http://localhost/static/kamara1.jpg',
          'url_cam2': '',
        },
      );

      provider.addMessage(message);
      await Future<void>.delayed(Duration.zero);

      expect(provider.items, hasLength(1));
      final item = provider.items.first;
      expect(item.type, NotifType.anomali);
      expect(item.title, '⚠️ Anomali');
      expect(item.body, 'Anomali terdeteksi');
      expect(item.deviceId, 'DEVICE_1');
      expect(item.analisisAi, 'AI mendeteksi suhu tinggi');
      expect(item.urlCam1, 'http://localhost/static/kamara1.jpg');
      expect(item.urlCam2, isNull);
    });

    test('ignores duplicate notifications within 60 seconds', () async {
      final message = RemoteMessage(
        messageId: 'msg1',
        data: {
          'type': 'ANOMALI',
          'device_id': 'DEVICE_1',
          'title': '⚠️ Anomali',
          'body': 'Anomali terdeteksi',
        },
      );

      provider.addMessage(message);
      await Future<void>.delayed(Duration.zero);
      provider.addMessage(message);
      await Future<void>.delayed(Duration.zero);

      expect(provider.items, hasLength(1));
    });

    test('classifies notifications using title when type is absent', () async {
      final message = RemoteMessage(
        messageId: 'msg2',
        data: {
          'title': '✅ Sukses — DEVICE_2',
          'body': 'Pakan berhasil dikirim',
        },
      );

      provider.addMessage(message);
      await Future<void>.delayed(Duration.zero);

      expect(provider.items, hasLength(1));
      expect(provider.items.first.type, NotifType.sukses);
    });

    test('removeItem deletes specific notification by id', () async {
      final message = RemoteMessage(
        messageId: 'msg3',
        data: {
          'type': 'SUKSES',
          'title': '✅ Sukses',
          'body': 'Notifikasi sukses',
        },
      );

      provider.addMessage(message);
      await Future<void>.delayed(Duration.zero);
      expect(provider.items, hasLength(1));

      provider.removeItem(provider.items.first.id);
      expect(provider.items, isEmpty);
    });

    test('clearAll removes all notification items and dedup keys', () async {
      final message = RemoteMessage(
        messageId: 'msg4',
        data: {
          'type': 'INFO',
          'title': 'Info',
          'body': 'Pesan info',
        },
      );

      provider.addMessage(message);
      await Future<void>.delayed(Duration.zero);
      expect(provider.items, hasLength(1));

      provider.clearAll();
      expect(provider.items, isEmpty);

      provider.addMessage(message);
      await Future<void>.delayed(Duration.zero);
      expect(provider.items, hasLength(1));
    });
  });
}
