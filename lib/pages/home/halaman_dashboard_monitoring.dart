// ================================================================
//  halaman_dashboard_monitoring.dart
//
//  Widget Dashboard Monitoring Terpusat
//  Menampilkan dua card:
//    1. Robot Feeder Status  — operasional robot di lapangan
//    2. Monitoring Device Health — integritas hardware ESP32
//
//  Koneksi API:
//    GET /api/{device_id}/status   → RobotStatusData
//    GET /api/monitoring-status/{device_id} → MonitoringHealthData
//
//  Refresh: polling setiap 10 detik (Timer.periodic)
// ================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

// ── Konstanta ────────────────────────────────────────────────────
const String kRobotId    = 'ROBOT-01';
const String kMonitorId  = 'ESP32-Moniitoring';
const double kPosisiMax  = 200.0; // cm — sesuaikan dengan panjang rel robot
const int    kOfflineTtl = 60;    // detik — > ini tampilkan WARNING di robot
const int    kErrorTtl   = 180;   // detik — > ini tampilkan OFFLINE di monitoring

// ── Warna status (sesuai PRD §3) ─────────────────────────────────
const _cHijau  = Color(0xFF16A34A);
const _cKuning = Color(0xFFF59E0B);
const _cMerah  = Color(0xFFEF4444);
const _cAbu    = Color(0xFF9CA3AF);
const _cSurface = Color(0xFFF8FAFC);
const _cCard   = Colors.white;

// ================================================================
//  MODEL — Robot
// ================================================================
class RobotStatusData {
  final String deviceId;
  final String mode;
  final String jadwalAktif;
  final double posisiCm;
  final bool   motorEnabled;
  final bool   limitMaju;
  final bool   limitMundur;
  final String mechState;
  final String subAktivitas;
  final bool   wifiOk;
  final bool   rtcOk;
  final double? detikSejak;

  const RobotStatusData({
    required this.deviceId,
    required this.mode,
    required this.jadwalAktif,
    required this.posisiCm,
    required this.motorEnabled,
    required this.limitMaju,
    required this.limitMundur,
    required this.mechState,
    required this.subAktivitas,
    required this.wifiOk,
    required this.rtcOk,
    this.detikSejak,
  });

  factory RobotStatusData.fromJson(Map<String, dynamic> j) => RobotStatusData(
    deviceId:     j['device_id']        ?? kRobotId,
    mode:         j['mode']             ?? 'IDLE',
    jadwalAktif:  j['jadwal_aktif']     ?? '-',
    posisiCm:     (j['posisi_cm']       ?? 0.0).toDouble(),
    motorEnabled: j['motor_enabled']    ?? false,
    limitMaju:    j['limit_maju']       ?? false,
    limitMundur:  j['limit_mundur']     ?? false,
    mechState:    j['mech_state']       ?? '-',
    subAktivitas: j['sub_aktivitas']    ?? 'Tidak diketahui',
    wifiOk:       j['wifi_ok']          ?? false,
    rtcOk:        j['rtc_ok']           ?? false,
    detikSejak:   (j['detik_sejak_lapor'] as num?)?.toDouble(),
  );
}

// ================================================================
//  MODEL — Monitoring Health
// ================================================================
class MonitoringHealthData {
  final String deviceId;
  final String deviceStatus;
  final int    detikSejak;
  // infrastruktur
  final bool wifiConnected;
  final bool rtcOk;
  final bool lcdOk;
  // sensor
  final bool sensorAirOk;
  final bool sensorPakanOk;
  final bool sensorPhOk;
  // operasional
  final String uiState;
  final int    jadwalTersinkronisasi;

  const MonitoringHealthData({
    required this.deviceId,
    required this.deviceStatus,
    required this.detikSejak,
    required this.wifiConnected,
    required this.rtcOk,
    required this.lcdOk,
    required this.sensorAirOk,
    required this.sensorPakanOk,
    required this.sensorPhOk,
    required this.uiState,
    required this.jadwalTersinkronisasi,
  });

  factory MonitoringHealthData.fromJson(Map<String, dynamic> j) {
    final data   = j['data'] as Map<String, dynamic>;
    final infra  = data['infrastruktur'] as Map<String, dynamic>;
    final sensor = data['sensor'] as Map<String, dynamic>;
    final ops    = data['operasional'] as Map<String, dynamic>;
    return MonitoringHealthData(
      deviceId:              data['device_id']     ?? kMonitorId,
      deviceStatus:          data['device_status'] ?? 'OFFLINE',
      detikSejak:            data['detik_sejak_heartbeat_terakhir'] ?? 9999,
      wifiConnected:         infra['wifi_connected']  ?? false,
      rtcOk:                 infra['rtc_ok']           ?? false,
      lcdOk:                 infra['lcd_ok']           ?? false,
      sensorAirOk:           sensor['ultrasonic_air_ok']   ?? false,
      sensorPakanOk:         sensor['ultrasonic_pakan_ok'] ?? false,
      sensorPhOk:            sensor['ph_ok']               ?? false,
      uiState:               ops['ui_state']               ?? '-',
      jadwalTersinkronisasi: ops['jadwal_tersinkronisasi']  ?? 0,
    );
  }

  bool get semuaSensorOk => sensorAirOk && sensorPakanOk && sensorPhOk;
  bool get semuaHardwareOk => rtcOk && lcdOk && wifiConnected;
}

// ================================================================
//  SERVICE — Fetch API
// ================================================================
class MonitoringApiService {
  static Future<RobotStatusData?> fetchRobot() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/$kRobotId/status'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return RobotStatusData.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<MonitoringHealthData?> fetchHealth() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/monitoring-status/$kMonitorId'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return MonitoringHealthData.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }
}

// ================================================================
//  HALAMAN UTAMA — dengan auto-refresh
// ================================================================
class HalamanDashboardMonitoring extends StatefulWidget {
  const HalamanDashboardMonitoring({super.key});

  @override
  State<HalamanDashboardMonitoring> createState() =>
      _HalamanDashboardMonitoringState();
}

class _HalamanDashboardMonitoringState
    extends State<HalamanDashboardMonitoring> {
  RobotStatusData?    _robot;
  MonitoringHealthData? _health;
  bool _loading = true;
  String? _error;
  Timer? _timer;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    final results = await Future.wait([
      MonitoringApiService.fetchRobot(),
      MonitoringApiService.fetchHealth(),
    ]);
    if (!mounted) return;
    setState(() {
      _robot   = results[0] as RobotStatusData?;
      _health  = results[1] as MonitoringHealthData?;
      _loading = false;
      _lastRefresh = DateTime.now();
      if (_robot == null && _health == null) {
        _error = 'Tidak dapat terhubung ke server.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSurface,
      appBar: AppBar(
        backgroundColor: _cSurface,
        elevation: 0,
        title: const Text(
          'Dashboard Monitoring',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (_lastRefresh != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Diperbarui ${_fmtWaktu(_lastRefresh!)}',
                  style: const TextStyle(fontSize: 11, color: _cAbu),
                ),
              ),
            ),
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _fetch,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: _cHijau,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) _buildErrorBanner(_error!),
            // ── Card 1: Robot Feeder ──────────────────────────────
            _CardRobotStatus(data: _robot),
            const SizedBox(height: 14),
            // ── Card 2: Monitoring Device Health ─────────────────
            _CardMonitoringHealth(data: _health),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _cMerah.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _cMerah.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.wifi_off_rounded, color: _cMerah, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(fontSize: 13, color: _cMerah))),
    ]),
  );

  String _fmtWaktu(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ================================================================
//  CARD 1 — Robot Feeder Status
// ================================================================
class _CardRobotStatus extends StatelessWidget {
  final RobotStatusData? data;
  const _CardRobotStatus({this.data});

  // Warna status badge mode
  Color _modeColor(String mode) => switch (mode) {
    'FEEDING' => _cHijau,
    'SCAN'    => _cKuning,
    'IDLE'    => _cAbu,
    _         => _cAbu,
  };

  // Teks mode dalam Bahasa Indonesia
  String _modeLabel(String mode) => switch (mode) {
    'FEEDING' => 'Memberi Pakan',
    'SCAN'    => 'Scanning Kandang',
    'IDLE'    => 'Siaga',
    _         => mode,
  };

  // Status koneksi robot berdasarkan detikSejak
  ({Color warna, String label, IconData ikon}) _koneksiStatus(double? detik) {
    if (detik == null) return (warna: _cAbu, label: 'Tidak Diketahui', ikon: Icons.help_outline_rounded);
    if (detik < kOfflineTtl) return (warna: _cHijau, label: 'Online', ikon: Icons.wifi_rounded);
    if (detik < kErrorTtl)   return (warna: _cKuning, label: 'Lambat', ikon: Icons.wifi_rounded);
    return (warna: _cMerah, label: 'Offline', ikon: Icons.wifi_off_rounded);
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) return _CardSkeleton(judul: 'Robot Feeder Status');

    final mode    = data!.mode;
    final modeClr = _modeColor(mode);
    final koneksi = _koneksiStatus(data!.detikSejak);
    final posisiPct = (data!.posisiCm / kPosisiMax).clamp(0.0, 1.0);
    final isLimit = data!.limitMaju || data!.limitMundur;

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: modeClr.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.precision_manufacturing_rounded,
                    color: modeClr, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Robot Feeder',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text(data!.deviceId,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              // Badge mode
              _StatusBadge(
                label: _modeLabel(mode),
                color: modeClr,
                dot: true,
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // ── Sub-aktivitas & jadwal ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  ikon: Icons.info_outline_rounded,
                  label: 'Aktivitas',
                  nilai: data!.subAktivitas.isEmpty ? '-' : data!.subAktivitas,
                  warna: modeClr,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  ikon: Icons.schedule_rounded,
                  label: 'Jadwal Aktif',
                  nilai: data!.jadwalAktif.isEmpty || data!.jadwalAktif == '-'
                      ? 'Tidak Ada'
                      : data!.jadwalAktif,
                  warna: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Visualizer Posisi ───────────────────────────────────
          _PosisiVisualizer(
            posisiPct: posisiPct,
            posisiCm: data!.posisiCm,
            limitMaju: data!.limitMaju,
            limitMundur: data!.limitMundur,
          ),

          const SizedBox(height: 14),

          // ── Status bawah ─────────────────────────────────────────
          Row(
            children: [
              // Motor
              Expanded(
                child: _ChipStatus(
                  ikon: data!.motorEnabled
                      ? Icons.electric_bolt_rounded
                      : Icons.power_off_rounded,
                  label: data!.motorEnabled ? 'Motor ON' : 'Motor OFF',
                  warna: data!.motorEnabled ? _cHijau : _cAbu,
                ),
              ),
              const SizedBox(width: 8),
              // Limit
              if (isLimit)
                Expanded(
                  child: _ChipStatus(
                    ikon: Icons.warning_amber_rounded,
                    label: data!.limitMaju ? 'Limit Maju' : 'Limit Mundur',
                    warna: _cKuning,
                  ),
                )
              else
                Expanded(
                  child: _ChipStatus(
                    ikon: Icons.check_circle_outline_rounded,
                    label: 'Jalur Aman',
                    warna: _cHijau,
                  ),
                ),
              const SizedBox(width: 8),
              // Koneksi
              Expanded(
                child: _ChipStatus(
                  ikon: koneksi.ikon,
                  label: koneksi.label,
                  warna: koneksi.warna,
                ),
              ),
            ],
          ),

          // Mech state — kecil di bawah
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.settings_rounded, size: 13, color: _cAbu),
            const SizedBox(width: 4),
            Text('State: ${data!.mechState}',
                style: const TextStyle(fontSize: 11, color: _cAbu)),
          ]),
        ],
      ),
    );
  }
}

// ================================================================
//  CARD 2 — Monitoring Device Health
// ================================================================
class _CardMonitoringHealth extends StatelessWidget {
  final MonitoringHealthData? data;
  const _CardMonitoringHealth({this.data});

  ({Color warna, String label, IconData ikon}) _deviceStatus() {
    if (data == null) return (warna: _cAbu, label: 'Tidak Diketahui', ikon: Icons.help_outline_rounded);
    if (data!.deviceStatus == 'OFFLINE' || data!.detikSejak > kErrorTtl)
      return (warna: _cMerah, label: 'OFFLINE', ikon: Icons.sensors_off_rounded);
    if (!data!.semuaHardwareOk || !data!.semuaSensorOk)
      return (warna: _cMerah, label: 'Error', ikon: Icons.error_outline_rounded);
    return (warna: _cHijau, label: 'Normal', ikon: Icons.sensors_rounded);
  }

  String _fmtDetik(int detik) {
    if (detik < 60)  return '${detik}d lalu';
    if (detik < 3600) return '${detik ~/ 60}m lalu';
    return '${detik ~/ 3600}j lalu';
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) return _CardSkeleton(judul: 'Monitoring Device Health');

    final status = _deviceStatus();

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status.warna.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(status.ikon, color: status.warna, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monitoring Device',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text(data!.deviceId,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              _StatusBadge(
                label: status.label,
                color: status.warna,
                dot: true,
              ),
            ],
          ),

          const SizedBox(height: 4),
          // Last heartbeat
          Row(children: [
            const SizedBox(width: 46),
            Icon(Icons.access_time_rounded, size: 12,
                color: data!.detikSejak > kErrorTtl ? _cMerah : _cAbu),
            const SizedBox(width: 4),
            Text(
              'Heartbeat: ${_fmtDetik(data!.detikSejak)}',
              style: TextStyle(
                fontSize: 11,
                color: data!.detikSejak > kErrorTtl ? _cMerah : _cAbu,
              ),
            ),
          ]),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // ── Grid Sensor 2×2 ─────────────────────────────────────
          const Text('Integritas Sensor',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SensorTile(
              label: 'Sensor Air',
              ok: data!.sensorAirOk,
              ikon: Icons.water_rounded,
            )),
            const SizedBox(width: 10),
            Expanded(child: _SensorTile(
              label: 'Sensor Pakan',
              ok: data!.sensorPakanOk,
              ikon: Icons.inventory_2_rounded,
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SensorTile(
              label: 'Sensor pH',
              ok: data!.sensorPhOk,
              ikon: Icons.science_rounded,
            )),
            // placeholder agar grid 2×2 simetris
            const SizedBox(width: 10),
            Expanded(child: _SensorTile(
              label: 'WiFi',
              ok: data!.wifiConnected,
              ikon: Icons.wifi_rounded,
            )),
          ]),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // ── Hardware Diagnostic ─────────────────────────────────
          const Text('Hardware Diagnostic',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _DiagnosticChip(
              label: 'LCD',
              ok: data!.lcdOk,
              ikon: Icons.monitor_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _DiagnosticChip(
              label: 'RTC',
              ok: data!.rtcOk,
              ikon: Icons.av_timer_rounded,
            )),
          ]),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // ── Operasional ─────────────────────────────────────────
          const Text('Status Operasional',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _InfoTile(
              ikon: Icons.widgets_rounded,
              label: 'UI State',
              nilai: data!.uiState.replaceFirst('UI_', ''),
              warna: const Color(0xFF7C3AED),
            )),
            const SizedBox(width: 10),
            Expanded(child: _InfoTile(
              ikon: Icons.sync_rounded,
              label: 'Jadwal Sync',
              nilai: '${data!.jadwalTersinkronisasi} jadwal',
              warna: const Color(0xFF0EA5E9),
            )),
          ]),
        ],
      ),
    );
  }
}

// ================================================================
//  WIDGET HELPERS
// ================================================================

class _BaseCard extends StatelessWidget {
  final Widget child;
  const _BaseCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _cCard,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(18),
    child: child,
  );
}

// ── Badge status (hijau/kuning/merah/abu + titik animasi) ─────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   dot;
  const _StatusBadge({required this.label, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );
}

// ── Tile info 2 baris (ikon + label kecil + nilai) ─────────────
class _InfoTile extends StatelessWidget {
  final IconData ikon;
  final String   label;
  final String   nilai;
  final Color    warna;
  const _InfoTile({
    required this.ikon, required this.label,
    required this.nilai, required this.warna,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: warna.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: warna.withOpacity(0.15)),
    ),
    child: Row(children: [
      Icon(ikon, size: 16, color: warna),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          Text(nilai,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: warna)),
        ],
      )),
    ]),
  );
}

// ── Chip status kecil (motor, limit, koneksi) ─────────────────
class _ChipStatus extends StatelessWidget {
  final IconData ikon;
  final String   label;
  final Color    warna;
  const _ChipStatus({required this.ikon, required this.label, required this.warna});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
    decoration: BoxDecoration(
      color: warna.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(ikon, size: 14, color: warna),
        const SizedBox(width: 5),
        Flexible(child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: warna))),
      ],
    ),
  );
}

// ── Tile sensor grid (label + ok/gagal) ──────────────────────
class _SensorTile extends StatelessWidget {
  final String   label;
  final bool     ok;
  final IconData ikon;
  const _SensorTile({required this.label, required this.ok, required this.ikon});

  @override
  Widget build(BuildContext context) {
    final c = ok ? _cHijau : _cMerah;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(ikon, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(ok ? 'Normal' : 'GAGAL',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c)),
          ],
        )),
        Icon(
          ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18, color: c,
        ),
      ]),
    );
  }
}

// ── Chip hardware diagnostic (LCD / RTC) ──────────────────────
class _DiagnosticChip extends StatelessWidget {
  final String   label;
  final bool     ok;
  final IconData ikon;
  const _DiagnosticChip({required this.label, required this.ok, required this.ikon});

  @override
  Widget build(BuildContext context) {
    final c = ok ? _cHijau : _cMerah;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(ikon, size: 16, color: c),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: c)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: c.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(ok ? 'OK' : 'ERROR',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: c)),
        ),
      ]),
    );
  }
}

// ── Visualizer posisi robot (progress bar horizontal) ─────────
class _PosisiVisualizer extends StatelessWidget {
  final double posisiPct;
  final double posisiCm;
  final bool   limitMaju;
  final bool   limitMundur;
  const _PosisiVisualizer({
    required this.posisiPct,
    required this.posisiCm,
    required this.limitMaju,
    required this.limitMundur,
  });

  @override
  Widget build(BuildContext context) {
    final isWarning = limitMaju || limitMundur;
    final trackColor = isWarning ? _cKuning : _cHijau;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Posisi Robot',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            Text('${posisiCm.toStringAsFixed(1)} cm',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Track background
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Filled portion
            FractionallySizedBox(
              widthFactor: posisiPct,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.home_rounded, size: 12,
                  color: limitMundur ? _cKuning : _cAbu),
              const SizedBox(width: 3),
              Text('Home', style: TextStyle(
                  fontSize: 10,
                  color: limitMundur ? _cKuning : _cAbu,
                  fontWeight: limitMundur ? FontWeight.w700 : FontWeight.normal)),
            ]),
            Row(children: [
              Text('Batas Akhir', style: TextStyle(
                  fontSize: 10,
                  color: limitMaju ? _cKuning : _cAbu,
                  fontWeight: limitMaju ? FontWeight.w700 : FontWeight.normal)),
              const SizedBox(width: 3),
              Icon(Icons.stop_rounded, size: 12,
                  color: limitMaju ? _cKuning : _cAbu),
            ]),
          ],
        ),
      ],
    );
  }
}

// ── Skeleton saat loading ────────────────────────────────────
class _CardSkeleton extends StatelessWidget {
  final String judul;
  const _CardSkeleton({required this.judul});

  @override
  Widget build(BuildContext context) => _BaseCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 80, height: 10,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(width: 130, height: 13,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4))),
          ]),
        ]),
        const SizedBox(height: 16),
        Container(height: 12, width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        Container(height: 12, width: 200,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 16),
        Row(children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(child: Container(height: 40,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10)))),
            if (i < 2) const SizedBox(width: 8),
          ]
        ]),
      ],
    ),
  );
}
