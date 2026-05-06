import 'package:flutter/material.dart';
import 'package:iot_ui_challenge/pages/home/halaman_dashboard.dart';
import 'package:iot_ui_challenge/pages/home/halaman_monitoring.dart';
import 'package:iot_ui_challenge/pages/home/halaman_notifikasi.dart';
import 'package:iot_ui_challenge/pages/home/halaman_history_pakan.dart';
import 'package:iot_ui_challenge/pages/home/halaman_pengaturan.dart';
import 'package:iot_ui_challenge/pages/home/halaman_feed_control.dart';
import 'package:iot_ui_challenge/pages/home/halaman_mitra.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:iot_ui_challenge/utils/notification_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // index bottom nav
  int _activePageIndex = 0; // index halaman di IndexedStack (termasuk notifikasi)
  // String? _selectedNotificationId = 'auto_feed';
  int _previousPageIndex = 0;

  void _gantiTab(int index) {
    setState(() {
      _selectedIndex = index;
      _activePageIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    
    // TANGKAP NOTIFIKASI SAAT APLIKASI TERBUKA
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Simpan ke dalam Provider
        context.read<NotificationProvider>().addMessage(message);
      }
    });
  }

  void _bukaMonitoring() {
    _gantiTab(1);
  }

  void _bukaNotifikasiDenganId(String id) {
    setState(() {
      // _selectedNotificationId = id;
      _previousPageIndex = _activePageIndex;
      _activePageIndex = 4; // halaman notifikasi (di luar bottom nav)
    });
  }

  void _bukaHalamanNotifikasi() {
    setState(() {
      _previousPageIndex = _activePageIndex;
      _activePageIndex = 4;
    });
  }

  void _bukaHistoryPakan() {
    setState(() {
      _previousPageIndex = _activePageIndex;
      _activePageIndex = 5;
    });
  }

  void _bukaHalamanMitra() {
    setState(() {
      _previousPageIndex = _activePageIndex;
      _activePageIndex = 6;
    });
  }

  // void _pilihNotifikasi(String id) {
  //   setState(() {
  //     _selectedNotificationId = id;
  //   });
  // }

  void _kembaliKeSebelumnya() {
    setState(() {
      _activePageIndex = _previousPageIndex;
      if (_previousPageIndex <= 3) {
        _selectedIndex = _previousPageIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: IndexedStack(
          index: _activePageIndex,
          children: [
            HalamanDashboard(
              onBukaMonitoring: _bukaMonitoring,
              onBukaNotifikasiDenganId: _bukaNotifikasiDenganId,
              onBukaHalamanNotifikasi: _bukaHalamanNotifikasi,
              onBukaHalamanMitra: _bukaHalamanMitra,
            ),
            HalamanMonitoring(
              onBukaHalamanNotifikasi: _bukaHalamanNotifikasi,
              onBukaHistoryPakan: _bukaHistoryPakan,
            ),
            HalamanFeedControl(
              onBukaHalamanNotifikasi: _bukaHalamanNotifikasi,
            ),
            HalamanPengaturan(
              onBukaHalamanNotifikasi: _bukaHalamanNotifikasi,
            ),
            HalamanNotifikasi(
              // selectedNotificationId: _selectedNotificationId,
              // onNotificationTap: _pilihNotifikasi,
              onBack: _kembaliKeSebelumnya,
            ),
            HalamanHistoryPakan(
              onBack: _kembaliKeSebelumnya,
            ),
            HalamanMitra(
              onBack: _kembaliKeSebelumnya,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF16A34A),
        unselectedItemColor: Colors.grey,
        onTap: _gantiTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye_outlined),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            label: 'Feed Control',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

