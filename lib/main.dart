import 'package:flutter/material.dart';
import 'package:iot_ui_challenge/pages/home/beranda_page.dart';
import 'package:provider/provider.dart';
import 'package:iot_ui_challenge/utils/sensor_provider.dart';
import 'package:iot_ui_challenge/utils/notification_provider.dart';
import 'package:iot_ui_challenge/service/api_refresh_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// ✅ WAJIB top-level (di luar semua class/fungsi)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Daftarkan background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Minta izin notifikasi
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Subscribe topik — samakan dengan topic di backend Python
  await FirebaseMessaging.instance.subscribeToTopic("semua_perangkat");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => ApiRefreshService()..startAll()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initFCMListeners();
  }

  void _initFCMListeners() {
    final notifProvider = context.read<NotificationProvider>();

    // ✅ Foreground — app sedang terbuka
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      notifProvider.addMessage(message);
    });

    // ✅ Background — user tap notifikasi lalu buka app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      notifProvider.addMessage(message);
    });

    // ✅ Terminated — app dibuka pertama kali dari tap notifikasi
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        notifProvider.addMessage(message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter IoT App UI',
      theme: ThemeData(
        fontFamily: "Poppins",
        sliderTheme: const SliderThemeData(
          trackShape: RectangularSliderTrackShape(),
          trackHeight: 2.5,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 15.0),
        ),
      ),
      home: const HomePage(),
    );
  }
}