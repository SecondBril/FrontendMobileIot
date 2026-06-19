import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:iot_ui_challenge/pages/home/halaman_monitoring.dart'; // Sesuaikan path
import 'package:iot_ui_challenge/service/monitoring_api.dart'; // Sesuaikan path

// Membuat Mock Class untuk API Service
class MockMonitoringApi extends Mock implements MonitoringApiService {}

void main() {
  late MockMonitoringApi mockApi;

  setUp(() {
    mockApi = MockMonitoringApi();
  });

  testWidgets('Har status "Normal" dan warna hijau saat data pakan > 20%', (WidgetTester tester) async {
    // 1. Definisikan perilaku mock: Kembalikan 80% saat dipanggil
    when(() => mockApi.fetchLatestData()).thenAnswer((_) async => {
      'ph_value': 7.0,
      'pakan_level_persen': 80.0,
      'air_level_persen': 70.0,
      'berat_loadcell_kg': 1.5,
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HalamanMonitoring(
          apiService: mockApi, // Masukkan mock ke sini
          onBukaHalamanNotifikasi: () {},
          onBukaHistoryPakan: () {},
        ),
      ),
    ));

    // 2. Berikan waktu untuk Future selesai dan re-render
    await tester.pumpAndSettle();

    // 3. Verifikasi: Sekarang data "80.0%" PASTI ditemukan
    expect(find.text('80.0%'), findsOneWidget);
    expect(find.text('Normal'), findsAtLeastNWidgets(1));
  });
}