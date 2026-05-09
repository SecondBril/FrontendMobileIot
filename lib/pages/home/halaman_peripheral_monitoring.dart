// ================================================================
//  halaman_peripheral_monitoring.dart
//
//  Halaman Detail Peripheral Monitoring — Robot Feeder v5.0
//  Menampilkan snapshot lengkap semua peripheral satu robot:
//    • Header status ringkas
//    • Card Motor & Stepper
//    • Card Servo Dispenser
//    • Card Limit Switch (Maju + Mundur)
//    • Card Kamera (CAM1 + CAM2)
//    • Card Upload Stats
//    • Card Sistem (RTC, WiFi, Heap, Uptime)
//
//  Dapat diakses dari:
//    - HalamanDashboardMonitoring → tombol "Detail Peripheral" di _CardRobotStatus
//    - Atau standalone via route /peripheral/:deviceId
//
//  Koneksi API:
//    GET /api/peripheral/{device_id}/status → PeripheralStatusData
//    GET /api/peripheral/{device_id}/events → List<PeripheralEvent>
//
//  Refresh: polling setiap 8 detik (Timer.periodic)
// ================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

// ── Warna (selaras dengan halaman_dashboard_monitoring.dart) ─────
const _cHijau   = Color(0xFF16A34A);
const _cKuning  = Color(0xFFF59E0B);
const _cMerah   = Color(0xFFEF4444);
const _cBiru    = Color(0xFF0EA5E9);
const _cUngu    = Color(0xFF7C3AED);
const _cAbu     = Color(0xFF9CA3AF);
const _cSurface = Color(0xFFF8FAFC);
const _cCard    = Colors.white;
const _cDivider = Color(0xFFF1F5F9);
const _cLabel   = Color(0xFF64748B);
const _cDark    = Color(0xFF0F172A);

// ── Threshold ─────────────────────────────────────────────────────
const int    kOfflineTtl  = 60;
const int    kErrorTtl    = 180;
const int    kHeapLow     = 30000;
const int    kHeapCritical = 20000;

// ================================================================
//  MODEL — Peripheral Status (dari GET /api/peripheral/{id}/status)
// ================================================================

class DriverMotorData {
  final bool   enPinState;
  final bool   dirPinState;
  final double stepFreqHz;
  final int    totalSteps;
  final bool   faultDetected;
  final bool   overtemp;
  const DriverMotorData({
    required this.enPinState, required this.dirPinState,
    required this.stepFreqHz, required this.totalSteps,
    required this.faultDetected, required this.overtemp,
  });
  factory DriverMotorData.fromJson(Map<String, dynamic> j) => DriverMotorData(
    enPinState:    j['en_pin_state']   ?? false,
    dirPinState:   j['dir_pin_state']  ?? false,
    stepFreqHz:    (j['step_freq_hz']  ?? 0.0).toDouble(),
    totalSteps:    j['total_steps']    ?? 0,
    faultDetected: j['fault_detected'] ?? false,
    overtemp:      j['overtemp']       ?? false,
  );
}

class StepperData {
  final int    posisiSteps;
  final double posisiCm;
  final int    targetSteps;
  final double targetCm;
  final int    distanceToGo;
  final double speedActual;
  final double speedMax;
  final double acceleration;
  final bool   isRunning;
  final bool   stallDetected;
  final int    stallCount;
  const StepperData({
    required this.posisiSteps, required this.posisiCm,
    required this.targetSteps, required this.targetCm,
    required this.distanceToGo, required this.speedActual,
    required this.speedMax, required this.acceleration,
    required this.isRunning, required this.stallDetected,
    required this.stallCount,
  });
  factory StepperData.fromJson(Map<String, dynamic> j) => StepperData(
    posisiSteps:  j['posisi_steps']   ?? 0,
    posisiCm:     (j['posisi_cm']     ?? 0.0).toDouble(),
    targetSteps:  j['target_steps']   ?? 0,
    targetCm:     (j['target_cm']     ?? 0.0).toDouble(),
    distanceToGo: j['distance_to_go'] ?? 0,
    speedActual:  (j['speed_actual']  ?? 0.0).toDouble(),
    speedMax:     (j['speed_max']     ?? 1200.0).toDouble(),
    acceleration: (j['acceleration']  ?? 600.0).toDouble(),
    isRunning:    j['is_running']     ?? false,
    stallDetected: j['stall_detected'] ?? false,
    stallCount:   j['stall_count']    ?? 0,
  );
}

class ServoData {
  final int     posisiDeg;
  final String  state;
  final String  dispState;
  final int     totalDispense;
  final int     durasiMsBuka;
  final String? waktuDispense;
  final int?    kandangTerakhir;
  const ServoData({
    required this.posisiDeg, required this.state,
    required this.dispState, required this.totalDispense,
    required this.durasiMsBuka, this.waktuDispense,
    this.kandangTerakhir,
  });
  factory ServoData.fromJson(Map<String, dynamic> j) => ServoData(
    posisiDeg:       j['posisi_deg']        ?? 0,
    state:           j['state']             ?? 'DIAM',
    dispState:       j['disp_state']        ?? '-',
    totalDispense:   j['total_dispense']    ?? 0,
    durasiMsBuka:    j['durasi_buka_ms']    ?? 0,
    waktuDispense:   j['waktu_dispense'],
    kandangTerakhir: j['kandang_terakhir'],
  );
}

class LimitSwitchData {
  final bool    pinState;
  final bool    aktifFlag;
  final int     totalTrigger;
  final int     debounceCount;
  final String? waktuTerakhir;
  final double? posisiTriggerCm;
  final String  label;
  const LimitSwitchData({
    required this.pinState, required this.aktifFlag,
    required this.totalTrigger, required this.debounceCount,
    this.waktuTerakhir, this.posisiTriggerCm,
    required this.label,
  });
  factory LimitSwitchData.fromJson(Map<String, dynamic> j) => LimitSwitchData(
    pinState:         j['pin_state']         ?? true,
    aktifFlag:        j['aktif_flag']        ?? false,
    totalTrigger:     j['total_trigger']     ?? 0,
    debounceCount:    j['debounce_count']    ?? 0,
    waktuTerakhir:    j['waktu_terakhir'],
    posisiTriggerCm:  (j['posisi_trigger_cm'] as num?)?.toDouble(),
    label:            j['label']             ?? '-',
  );
  bool get isAktif => !pinState;
}

class CamData {
  final String status;
  final String rxState;
  final int    bytesRxTotal;
  final int    bytesTxTotal;
  final int?   lastJpegSize;
  final bool?  lastJpegOk;
  final int    sessionCount;
  final int    errorCount;
  final int    timeoutCount;
  final double errorRatePct;
  final String? lastRxWaktu;
  final int?   bufferAvailable;
  const CamData({
    required this.status, required this.rxState,
    required this.bytesRxTotal, required this.bytesTxTotal,
    this.lastJpegSize, this.lastJpegOk,
    required this.sessionCount, required this.errorCount,
    required this.timeoutCount, required this.errorRatePct,
    this.lastRxWaktu, this.bufferAvailable,
  });
  factory CamData.fromJson(Map<String, dynamic> j) => CamData(
    status:          j['status']           ?? 'UNKNOWN',
    rxState:         j['rx_state']         ?? '-',
    bytesRxTotal:    j['bytes_rx_total']   ?? 0,
    bytesTxTotal:    j['bytes_tx_total']   ?? 0,
    lastJpegSize:    j['last_jpeg_size'],
    lastJpegOk:      j['last_jpeg_ok'],
    sessionCount:    j['session_count']    ?? 0,
    errorCount:      j['error_count']      ?? 0,
    timeoutCount:    j['timeout_count']    ?? 0,
    errorRatePct:    (j['error_rate_pct']  ?? 0.0).toDouble(),
    lastRxWaktu:     j['last_rx_waktu'],
    bufferAvailable: j['buffer_available'],
  );
  Color get statusColor => switch (status) {
    'READY'   => _cHijau,
    'OFFLINE' => _cMerah,
    'ERROR'   => _cMerah,
    'TIMEOUT' => _cKuning,
    _         => _cAbu,
  };
}

class UploadData {
  final int     totalOk;
  final int     totalGagal;
  final double  successRatePct;
  final int     bytesTerkirim;
  final String? lastStatus;
  final int?    lastHttpCode;
  final String? lastWaktu;
  const UploadData({
    required this.totalOk, required this.totalGagal,
    required this.successRatePct, required this.bytesTerkirim,
    this.lastStatus, this.lastHttpCode, this.lastWaktu,
  });
  factory UploadData.fromJson(Map<String, dynamic> j) => UploadData(
    totalOk:        j['total_ok']         ?? 0,
    totalGagal:     j['total_gagal']      ?? 0,
    successRatePct: (j['success_rate_pct'] ?? 0.0).toDouble(),
    bytesTerkirim:  j['bytes_terkirim']   ?? 0,
    lastStatus:     j['last_status'],
    lastHttpCode:   j['last_http_code'],
    lastWaktu:      j['last_waktu'],
  );
}

class RtcData {
  final bool   ok;
  final bool   lostPower;
  final double? tempCelsius;
  final bool   ntpSynced;
  const RtcData({
    required this.ok, required this.lostPower,
    this.tempCelsius, required this.ntpSynced,
  });
  factory RtcData.fromJson(Map<String, dynamic> j) => RtcData(
    ok:          j['ok']           ?? false,
    lostPower:   j['lost_power']   ?? false,
    tempCelsius: (j['temp_celsius'] as num?)?.toDouble(),
    ntpSynced:   j['ntp_synced']   ?? false,
  );
}

class WifiData {
  final bool   connected;
  final int?   rssi;
  final String rssiLabel;
  final String? ip;
  final int    reconnectCount;
  const WifiData({
    required this.connected, this.rssi,
    required this.rssiLabel, this.ip,
    required this.reconnectCount,
  });
  factory WifiData.fromJson(Map<String, dynamic> j) => WifiData(
    connected:       j['connected']       ?? false,
    rssi:            j['rssi'],
    rssiLabel:       j['rssi_label']      ?? '-',
    ip:              j['ip'],
    reconnectCount:  j['reconnect_count'] ?? 0,
  );
}

class SistemData {
  final int?   heapFreeBytes;
  final String heapStatus;
  final int    uptimeDetik;
  final String uptimeLabel;
  final int?   core0StackFree;
  final int?   core1StackFree;
  const SistemData({
    this.heapFreeBytes, required this.heapStatus,
    required this.uptimeDetik, required this.uptimeLabel,
    this.core0StackFree, this.core1StackFree,
  });
  factory SistemData.fromJson(Map<String, dynamic> j) => SistemData(
    heapFreeBytes:  j['heap_free_bytes'],
    heapStatus:     j['heap_status']     ?? 'UNKNOWN',
    uptimeDetik:    j['uptime_detik']    ?? 0,
    uptimeLabel:    j['uptime_label']    ?? '-',
    core0StackFree: j['core0_stack_free'],
    core1StackFree: j['core1_stack_free'],
  );
  Color get heapColor => switch (heapStatus) {
    'NORMAL'   => _cHijau,
    'LOW'      => _cKuning,
    'CRITICAL' => _cMerah,
    _          => _cAbu,
  };
}

class PeripheralStatusData {
  final String         deviceId;
  final String?        waktuRtc;
  final String?        waktuTerima;
  final double?        detikSejak;
  final DriverMotorData driverMotor;
  final StepperData    stepper;
  final ServoData      servo;
  final LimitSwitchData limitMaju;
  final LimitSwitchData limitMundur;
  final CamData        cam1;
  final CamData        cam2;
  final UploadData     upload;
  final RtcData        rtc;
  final WifiData       wifi;
  final SistemData     sistem;

  const PeripheralStatusData({
    required this.deviceId, this.waktuRtc, this.waktuTerima,
    this.detikSejak,
    required this.driverMotor, required this.stepper,
    required this.servo, required this.limitMaju,
    required this.limitMundur, required this.cam1,
    required this.cam2, required this.upload,
    required this.rtc, required this.wifi, required this.sistem,
  });

  factory PeripheralStatusData.fromJson(Map<String, dynamic> j) =>
      PeripheralStatusData(
        deviceId:    j['device_id']           ?? '-',
        waktuRtc:    j['waktu_rtc'],
        waktuTerima: j['waktu_terima'],
        detikSejak:  (j['detik_sejak_lapor'] as num?)?.toDouble(),
        driverMotor: DriverMotorData.fromJson(j['driver_motor'] ?? {}),
        stepper:     StepperData.fromJson(j['stepper'] ?? {}),
        servo:       ServoData.fromJson(j['servo'] ?? {}),
        limitMaju:   LimitSwitchData.fromJson(j['limit_maju'] ?? {}),
        limitMundur: LimitSwitchData.fromJson(j['limit_mundur'] ?? {}),
        cam1:        CamData.fromJson(j['cam1'] ?? {}),
        cam2:        CamData.fromJson(j['cam2'] ?? {}),
        upload:      UploadData.fromJson(j['upload'] ?? {}),
        rtc:         RtcData.fromJson(j['rtc'] ?? {}),
        wifi:        WifiData.fromJson(j['wifi'] ?? {}),
        sistem:      SistemData.fromJson(j['sistem'] ?? {}),
      );
}

class PeripheralEvent {
  final int     id;
  final String? waktuRtc;
  final String  eventType;
  final String  peripheral;
  final String  severity;
  final String? keterangan;
  const PeripheralEvent({
    required this.id, this.waktuRtc,
    required this.eventType, required this.peripheral,
    required this.severity, this.keterangan,
  });
  factory PeripheralEvent.fromJson(Map<String, dynamic> j) => PeripheralEvent(
    id:          j['id']          ?? 0,
    waktuRtc:    j['waktu_rtc'],
    eventType:   j['event_type']  ?? '-',
    peripheral:  j['peripheral']  ?? '-',
    severity:    j['severity']    ?? 'INFO',
    keterangan:  j['keterangan'],
  );
  Color get severityColor => switch (severity) {
    'CRITICAL' => _cMerah,
    'ERROR'    => _cMerah,
    'WARNING'  => _cKuning,
    'INFO'     => _cBiru,
    _          => _cAbu,
  };
  IconData get severityIcon => switch (severity) {
    'CRITICAL' => Icons.error_rounded,
    'ERROR'    => Icons.cancel_rounded,
    'WARNING'  => Icons.warning_amber_rounded,
    _          => Icons.info_outline_rounded,
  };
}

// ================================================================
//  SERVICE
// ================================================================
class PeripheralApiService {
  static Future<PeripheralStatusData?> fetchStatus(String deviceId) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/peripheral/$deviceId/status'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        return PeripheralStatusData.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<PeripheralEvent>> fetchEvents(String deviceId) async {
    try {
      final res = await http
          .get(Uri.parse(
              '${ApiConfig.baseUrl}/api/peripheral/$deviceId/events?limit=20'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => PeripheralEvent.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}

// ================================================================
//  HALAMAN UTAMA
// ================================================================
class HalamanPeripheralMonitoring extends StatefulWidget {
  final String deviceId;
  const HalamanPeripheralMonitoring({
    super.key,
    required this.deviceId,
  });

  @override
  State<HalamanPeripheralMonitoring> createState() =>
      _HalamanPeripheralMonitoringState();
}

class _HalamanPeripheralMonitoringState
    extends State<HalamanPeripheralMonitoring> {
  PeripheralStatusData? _data;
  List<PeripheralEvent> _events = [];
  bool   _loading = true;
  String? _error;
  Timer? _timer;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    final results = await Future.wait([
      PeripheralApiService.fetchStatus(widget.deviceId),
      PeripheralApiService.fetchEvents(widget.deviceId),
    ]);
    if (!mounted) return;
    setState(() {
      _data    = results[0] as PeripheralStatusData?;
      _events  = results[1] as List<PeripheralEvent>;
      _loading = false;
      _lastRefresh = DateTime.now();
      if (_data == null) _error = 'Tidak dapat terhubung ke server.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSurface,
      appBar: AppBar(
        backgroundColor: _cSurface,
        elevation: 0,
        leading: const BackButton(color: _cDark),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Peripheral Monitoring',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: _cDark)),
            Text(widget.deviceId,
                style: const TextStyle(fontSize: 11, color: _cAbu)),
          ],
        ),
        actions: [
          if (_lastRefresh != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  _fmtWaktu(_lastRefresh!),
                  style: const TextStyle(fontSize: 10, color: _cAbu),
                ),
              ),
            ),
          IconButton(
            icon: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _cBiru))
                : const Icon(Icons.refresh_rounded, color: _cLabel, size: 20),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: _cHijau,
        child: _data == null && !_loading
            ? _buildErrorState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  if (_error != null) _buildErrorBanner(_error!),

                  // ── Status Header Bar ─────────────────────────────
                  if (_data != null) _StatusHeaderBar(data: _data!),
                  const SizedBox(height: 12),

                  // ── Motor & Stepper ───────────────────────────────
                  _SectionLabel(label: 'Motor & Penggerak'),
                  const SizedBox(height: 8),
                  _CardMotorStepper(
                    motor: _data?.driverMotor,
                    stepper: _data?.stepper,
                  ),
                  const SizedBox(height: 12),

                  // ── Servo ─────────────────────────────────────────
                  _SectionLabel(label: 'Dispenser Servo'),
                  const SizedBox(height: 8),
                  _CardServo(data: _data?.servo),
                  const SizedBox(height: 12),

                  // ── Limit Switch ──────────────────────────────────
                  _SectionLabel(label: 'Limit Switch'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _CardLimitSwitch(
                        label: 'Limit Maju', data: _data?.limitMaju,
                        ikon: Icons.arrow_forward_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _CardLimitSwitch(
                        label: 'Limit Mundur / Home', data: _data?.limitMundur,
                        ikon: Icons.home_rounded)),
                  ]),
                  const SizedBox(height: 12),

                  // ── Kamera ────────────────────────────────────────
                  _SectionLabel(label: 'Kamera Serial'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _CardKamera(
                        label: 'CAM 1 (Ayam)', data: _data?.cam1)),
                    const SizedBox(width: 10),
                    Expanded(child: _CardKamera(
                        label: 'CAM 2 (Pakan)', data: _data?.cam2)),
                  ]),
                  const SizedBox(height: 12),

                  // ── Upload ────────────────────────────────────────
                  _SectionLabel(label: 'Upload JPEG'),
                  const SizedBox(height: 8),
                  _CardUpload(data: _data?.upload),
                  const SizedBox(height: 12),

                  // ── Sistem (RTC + WiFi + Heap) ────────────────────
                  _SectionLabel(label: 'Sistem & Infrastruktur'),
                  const SizedBox(height: 8),
                  _CardSistem(
                    rtc: _data?.rtc,
                    wifi: _data?.wifi,
                    sistem: _data?.sistem,
                  ),
                  const SizedBox(height: 12),

                  // ── Riwayat Event ─────────────────────────────────
                  _SectionLabel(label: 'Riwayat Event Terbaru'),
                  const SizedBox(height: 8),
                  _CardEventLog(events: _events),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.signal_wifi_connected_no_internet_4_rounded,
              color: _cMerah, size: 48),
          const SizedBox(height: 16),
          const Text('Tidak dapat terhubung ke server.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: _cDark)),
          const SizedBox(height: 8),
          Text('Periksa koneksi dan pastikan perangkat ${widget.deviceId} aktif.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _cLabel)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );

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

  String _fmtWaktu(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}

// ================================================================
//  WIDGET — Status Header Bar
// ================================================================
class _StatusHeaderBar extends StatelessWidget {
  final PeripheralStatusData data;
  const _StatusHeaderBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final detik = data.detikSejak;
    Color koneksiColor;
    String koneksiLabel;
    if (detik == null) {
      koneksiColor = _cAbu; koneksiLabel = 'Tidak Diketahui';
    } else if (detik < kOfflineTtl) {
      koneksiColor = _cHijau; koneksiLabel = 'Online';
    } else if (detik < kErrorTtl) {
      koneksiColor = _cKuning; koneksiLabel = 'Lambat';
    } else {
      koneksiColor = _cMerah; koneksiLabel = 'Offline';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        _MiniStat(label: 'Koneksi', nilai: koneksiLabel, warna: koneksiColor),
        _vDivider(),
        _MiniStat(label: 'Laporan', nilai: _fmtDetik(detik),
            warna: koneksiColor),
        _vDivider(),
        _MiniStat(label: 'Waktu RTC',
            nilai: data.waktuRtc?.substring(11) ?? '-',
            warna: _cBiru),
        _vDivider(),
        _MiniStat(label: 'Uptime',
            nilai: data.sistem.uptimeLabel,
            warna: _cLabel),
      ]),
    );
  }

  String _fmtDetik(double? d) {
    if (d == null) return '-';
    if (d < 60) return '${d.toStringAsFixed(0)}d lalu';
    if (d < 3600) return '${(d / 60).floor()}m lalu';
    return '${(d / 3600).floor()}j lalu';
  }

  Widget _vDivider() => Container(
      height: 32, width: 0.5,
      color: _cDivider,
      margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _MiniStat extends StatelessWidget {
  final String label, nilai;
  final Color warna;
  const _MiniStat({required this.label, required this.nilai, required this.warna});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: _cAbu)),
      const SizedBox(height: 2),
      Text(nilai,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: warna)),
    ]),
  );
}

// ================================================================
//  WIDGET — Section Label
// ================================================================
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: _cLabel, letterSpacing: 0.5)),
  );
}

// ================================================================
//  CARD — Motor & Stepper
// ================================================================
class _CardMotorStepper extends StatelessWidget {
  final DriverMotorData? motor;
  final StepperData?     stepper;
  const _CardMotorStepper({this.motor, this.stepper});

  @override
  Widget build(BuildContext context) {
    if (motor == null || stepper == null) return const _SkeletonCard();

    final motorAktif = motor!.enPinState;
    final hasFault   = motor!.faultDetected || motor!.overtemp;
    final motorColor = hasFault ? _cMerah
        : motorAktif ? _cHijau : _cAbu;

    final posisiPct = (stepper!.posisiCm / 200.0).clamp(0.0, 1.0);
    final targetPct = (stepper!.targetCm / 200.0).clamp(0.0, 1.0);

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          _CardHeader(
            ikon: Icons.electric_bolt_rounded,
            ikonColor: motorColor,
            judul: 'Driver Motor A4988',
            trailing: Row(children: [
              if (hasFault)
                _Badge(label: motor!.faultDetected ? 'FAULT' : 'OVERTEMP',
                    color: _cMerah),
              if (!hasFault) _Badge(
                  label: motorAktif ? 'ENABLE' : 'DISABLE', color: motorColor),
            ]),
          ),
          const _Divider(),

          // Motor chips
          Row(children: [
            Expanded(child: _MetricChip(
              label: 'Arah', nilai: motor!.dirPinState ? 'MAJU →' : '← MUNDUR',
              warna: motor!.dirPinState ? _cBiru : _cUngu,
              ikon: motor!.dirPinState
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Frekuensi STEP',
              nilai: '${motor!.stepFreqHz.toStringAsFixed(0)} Hz',
              warna: _cBiru,
              ikon: Icons.speed_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Total STEP',
              nilai: _fmtBigNum(motor!.totalSteps),
              warna: _cLabel,
              ikon: Icons.linear_scale_rounded,
            )),
          ]),
          const SizedBox(height: 14),
          const _Divider(),
          const SizedBox(height: 12),

          // Stepper header
          Row(children: [
            const Icon(Icons.settings_input_component_rounded,
                size: 16, color: _cLabel),
            const SizedBox(width: 6),
            const Text('Stepper AccelStepper',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _cLabel)),
            const Spacer(),
            _Badge(
              label: stepper!.isRunning ? 'Running' : 'Idle',
              color: stepper!.isRunning ? _cHijau : _cAbu,
            ),
            if (stepper!.stallDetected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _Badge(
                    label: 'STALL ×${stepper!.stallCount}', color: _cMerah),
              ),
          ]),
          const SizedBox(height: 10),

          // Posisi visual
          _PosisiTrack(
            posisiPct: posisiPct,
            targetPct: targetPct,
            posisiCm: stepper!.posisiCm,
            targetCm: stepper!.targetCm,
            warna: stepper!.isRunning ? _cBiru : _cAbu,
          ),
          const SizedBox(height: 12),

          // Stepper metrics
          Row(children: [
            Expanded(child: _MetricChip(
              label: 'Kecepatan', warna: _cBiru,
              nilai: '${stepper!.speedActual.toStringAsFixed(0)} stp/s',
              ikon: Icons.speed_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Max Speed', warna: _cLabel,
              nilai: '${stepper!.speedMax.toStringAsFixed(0)} stp/s',
              ikon: Icons.timer_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Akselerasi', warna: _cLabel,
              nilai: '${stepper!.acceleration.toStringAsFixed(0)} stp/s²',
              ikon: Icons.trending_up_rounded,
            )),
          ]),
          const SizedBox(height: 8),

          // Posisi steps row
          Row(children: [
            const Icon(Icons.pin_drop_rounded, size: 12, color: _cAbu),
            const SizedBox(width: 4),
            Text('Posisi: ${stepper!.posisiSteps} steps  '
                '|  Target: ${stepper!.targetSteps} steps  '
                '|  Sisa: ${stepper!.distanceToGo} steps',
                style: const TextStyle(fontSize: 11, color: _cAbu)),
          ]),
        ],
      ),
    );
  }

  String _fmtBigNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ================================================================
//  CARD — Servo Dispenser
// ================================================================
class _CardServo extends StatelessWidget {
  final ServoData? data;
  const _CardServo({this.data});

  Color _stateColor(String s) => switch (s) {
    'BUKA'      => _cHijau,
    'TUTUP'     => _cBiru,
    'TRANSISI'  => _cKuning,
    _           => _cAbu,
  };

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _SkeletonCard();
    final c = _stateColor(data!.state);

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            ikon: Icons.rotate_90_degrees_cw_rounded,
            ikonColor: c,
            judul: 'Servo Dispenser',
            trailing: _Badge(label: data!.state, color: c),
          ),
          const _Divider(),

          Row(children: [
            Expanded(child: _MetricChip(
              label: 'Posisi Servo', warna: c,
              nilai: '${data!.posisiDeg}°',
              ikon: Icons.donut_large_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Total Dispense', warna: _cHijau,
              nilai: '${data!.totalDispense}×',
              ikon: Icons.restaurant_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Durasi Buka', warna: _cBiru,
              nilai: '${data!.durasiMsBuka} ms',
              ikon: Icons.timer_outlined,
            )),
          ]),
          const SizedBox(height: 10),

          // Kandang & waktu
          if (data!.kandangTerakhir != null)
            _InfoRow(
              ikon: Icons.home_work_rounded,
              label: 'Kandang Terakhir',
              nilai: 'Kandang ${data!.kandangTerakhir! + 1}',
              warna: _cUngu,
            ),
          if (data!.waktuDispense != null)
            _InfoRow(
              ikon: Icons.schedule_rounded,
              label: 'Waktu Dispense',
              nilai: data!.waktuDispense!,
              warna: _cLabel,
            ),

          const SizedBox(height: 8),
          // Disp state bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _cSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cDivider),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: _cAbu),
              const SizedBox(width: 6),
              Text('Disp State: ', style: const TextStyle(fontSize: 11, color: _cAbu)),
              Text(data!.dispState,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _cLabel)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  CARD — Limit Switch
// ================================================================
class _CardLimitSwitch extends StatelessWidget {
  final String         label;
  final LimitSwitchData? data;
  final IconData       ikon;
  const _CardLimitSwitch({required this.label, this.data, required this.ikon});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _SkeletonCard(minHeight: 160);
    final isAktif = data!.isAktif;
    final c = isAktif ? _cKuning : _cHijau;

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(ikon, size: 17, color: c),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _cDark))),
            _Badge(label: isAktif ? 'AKTIF' : 'Aman', color: c),
          ]),
          const SizedBox(height: 10),
          const _Divider(),
          const SizedBox(height: 10),

          _MiniRow(label: 'Total Trigger',
              nilai: '${data!.totalTrigger}×', warna: c),
          const SizedBox(height: 6),
          _MiniRow(label: 'Debounce',
              nilai: '${data!.debounceCount}×', warna: _cAbu),
          if (data!.posisiTriggerCm != null) ...[
            const SizedBox(height: 6),
            _MiniRow(label: 'Posisi Trigger',
                nilai: '${data!.posisiTriggerCm!.toStringAsFixed(1)} cm',
                warna: _cBiru),
          ],
          if (data!.waktuTerakhir != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 12, color: _cAbu),
              const SizedBox(width: 4),
              Expanded(child: Text(data!.waktuTerakhir!,
                  style: const TextStyle(fontSize: 10, color: _cAbu),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ],
      ),
    );
  }
}

// ================================================================
//  CARD — Kamera
// ================================================================
class _CardKamera extends StatelessWidget {
  final String   label;
  final CamData? data;
  const _CardKamera({required this.label, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _SkeletonCard(minHeight: 220);
    final c = data!.statusColor;

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.videocam_rounded, size: 17, color: c),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _cDark))),
            _Badge(label: data!.status, color: c),
          ]),
          const SizedBox(height: 10),
          const _Divider(),
          const SizedBox(height: 10),

          _MiniRow(label: 'Sesi', nilai: '${data!.sessionCount}', warna: _cBiru),
          const SizedBox(height: 5),
          _MiniRow(label: 'Error',
              nilai: '${data!.errorCount} (${data!.errorRatePct.toStringAsFixed(1)}%)',
              warna: data!.errorCount > 0 ? _cMerah : _cHijau),
          const SizedBox(height: 5),
          _MiniRow(label: 'Timeout',
              nilai: '${data!.timeoutCount}',
              warna: data!.timeoutCount > 0 ? _cKuning : _cHijau),
          const SizedBox(height: 5),
          _MiniRow(label: 'RX Total',
              nilai: _fmtBytes(data!.bytesRxTotal), warna: _cLabel),
          if (data!.lastJpegSize != null) ...[
            const SizedBox(height: 5),
            _MiniRow(label: 'JPEG Terakhir',
                nilai: '${_fmtBytes(data!.lastJpegSize!)} '
                    '${data!.lastJpegOk == true ? "✓" : data!.lastJpegOk == false ? "✗" : ""}',
                warna: data!.lastJpegOk == true ? _cHijau
                    : data!.lastJpegOk == false ? _cMerah : _cLabel),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: _cSurface,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(children: [
              const Icon(Icons.fiber_smart_record_rounded,
                  size: 11, color: _cAbu),
              const SizedBox(width: 5),
              Expanded(child: Text('RX: ${data!.rxState}',
                  style: const TextStyle(fontSize: 10, color: _cAbu),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ],
      ),
    );
  }

  String _fmtBytes(int b) {
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    if (b >= 1024)    return '${(b / 1024).toStringAsFixed(1)} KB';
    return '$b B';
  }
}

// ================================================================
//  CARD — Upload
// ================================================================
class _CardUpload extends StatelessWidget {
  final UploadData? data;
  const _CardUpload({this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _SkeletonCard();
    final successColor = data!.successRatePct >= 90 ? _cHijau
        : data!.successRatePct >= 70 ? _cKuning : _cMerah;
    final lastColor = data!.lastStatus == 'OK' ? _cHijau
        : data!.lastStatus == 'GAGAL' ? _cMerah : _cAbu;

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            ikon: Icons.cloud_upload_rounded,
            ikonColor: successColor,
            judul: 'Upload JPEG ke Server',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${data!.successRatePct.toStringAsFixed(1)}% sukses',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: successColor)),
            ),
          ),
          const _Divider(),

          Row(children: [
            Expanded(child: _MetricChip(
              label: 'Total Sukses', warna: _cHijau,
              nilai: '${data!.totalOk}', ikon: Icons.check_circle_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Total Gagal', warna: _cMerah,
              nilai: '${data!.totalGagal}', ikon: Icons.cancel_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Data Terkirim', warna: _cBiru,
              nilai: _fmtBytes(data!.bytesTerkirim),
              ikon: Icons.data_usage_rounded,
            )),
          ]),
          const SizedBox(height: 10),

          // Progress bar sukses rate
          _ProgressBar(
            label: 'Success Rate',
            pct: data!.successRatePct / 100,
            warna: successColor,
          ),
          const SizedBox(height: 10),

          // Last upload info
          Row(children: [
            _Badge(
              label: data!.lastStatus == null ? 'Belum Ada'
                  : 'HTTP ${data!.lastHttpCode ?? "?"}  ${data!.lastStatus}',
              color: lastColor,
            ),
            if (data!.lastWaktu != null) ...[
              const SizedBox(width: 8),
              Expanded(child: Row(children: [
                const Icon(Icons.schedule_rounded, size: 11, color: _cAbu),
                const SizedBox(width: 4),
                Flexible(child: Text(data!.lastWaktu!,
                    style: const TextStyle(fontSize: 10, color: _cAbu),
                    overflow: TextOverflow.ellipsis)),
              ])),
            ],
          ]),
        ],
      ),
    );
  }

  String _fmtBytes(int b) {
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    if (b >= 1024)    return '${(b / 1024).toStringAsFixed(1)} KB';
    return '$b B';
  }
}

// ================================================================
//  CARD — Sistem
// ================================================================
class _CardSistem extends StatelessWidget {
  final RtcData?    rtc;
  final WifiData?   wifi;
  final SistemData? sistem;
  const _CardSistem({this.rtc, this.wifi, this.sistem});

  @override
  Widget build(BuildContext context) {
    if (rtc == null || wifi == null || sistem == null) {
      return const _SkeletonCard(minHeight: 200);
    }

    final wifiColor = wifi!.connected ? _cHijau : _cMerah;
    final rtcColor  = rtc!.ok ? _cHijau : _cMerah;
    final heapColor = sistem!.heapColor;
    final rssi      = wifi!.rssi ?? -100;
    final rssiPct   = ((rssi + 100) / 60).clamp(0.0, 1.0);

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            ikon: Icons.memory_rounded,
            ikonColor: heapColor,
            judul: 'Sistem & Infrastruktur',
            trailing: _Badge(
              label: sistem!.heapStatus,
              color: heapColor,
            ),
          ),
          const _Divider(),

          // Baris 1: RTC + WiFi
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.av_timer_rounded, size: 14, color: _cLabel),
                  const SizedBox(width: 5),
                  const Text('RTC DS3231',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: _cLabel)),
                  const Spacer(),
                  _Badge(label: rtc!.ok ? 'OK' : 'ERROR', color: rtcColor),
                ]),
                const SizedBox(height: 8),
                _MiniRow(label: 'NTP Sync',
                    nilai: rtc!.ntpSynced ? 'Tersinkron' : 'Tidak Sync',
                    warna: rtc!.ntpSynced ? _cHijau : _cKuning),
                const SizedBox(height: 4),
                _MiniRow(label: 'Lost Power',
                    nilai: rtc!.lostPower ? 'Pernah Mati' : 'Normal',
                    warna: rtc!.lostPower ? _cKuning : _cHijau),
                if (rtc!.tempCelsius != null) ...[
                  const SizedBox(height: 4),
                  _MiniRow(label: 'Suhu Internal',
                      nilai: '${rtc!.tempCelsius!.toStringAsFixed(1)}°C',
                      warna: _cBiru),
                ],
              ],
            )),
            Container(width: 0.5, height: 90, color: _cDivider,
                margin: const EdgeInsets.symmetric(horizontal: 14)),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.wifi_rounded, size: 14, color: _cLabel),
                  const SizedBox(width: 5),
                  const Text('WiFi',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: _cLabel)),
                  const Spacer(),
                  _Badge(label: wifi!.connected ? 'Online' : 'Offline',
                      color: wifiColor),
                ]),
                const SizedBox(height: 8),
                _ProgressBar(
                  label: 'RSSI: ${wifi!.rssi ?? "?"} dBm (${wifi!.rssiLabel})',
                  pct: rssiPct,
                  warna: wifiColor,
                ),
                const SizedBox(height: 6),
                _MiniRow(label: 'IP', nilai: wifi!.ip ?? '-', warna: _cBiru),
                const SizedBox(height: 4),
                _MiniRow(label: 'Reconnect',
                    nilai: '${wifi!.reconnectCount}×',
                    warna: wifi!.reconnectCount > 0 ? _cKuning : _cHijau),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          const _Divider(),
          const SizedBox(height: 12),

          // Heap memory
          _ProgressBar(
            label: 'Heap Free: ${_fmtBytes(sistem!.heapFreeBytes ?? 0)} '
                '(${sistem!.heapStatus})',
            pct: ((sistem!.heapFreeBytes ?? 0) / 320000).clamp(0.0, 1.0),
            warna: heapColor,
          ),
          const SizedBox(height: 10),

          // Core stacks + uptime
          Row(children: [
            Expanded(child: _MetricChip(
              label: 'Core 0 Stack', warna: _cLabel,
              nilai: _fmtBytes(sistem!.core0StackFree ?? 0),
              ikon: Icons.developer_board_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Core 1 Stack', warna: _cLabel,
              nilai: _fmtBytes(sistem!.core1StackFree ?? 0),
              ikon: Icons.developer_board_rounded,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricChip(
              label: 'Uptime', warna: _cBiru,
              nilai: sistem!.uptimeLabel,
              ikon: Icons.access_time_rounded,
            )),
          ]),
        ],
      ),
    );
  }

  String _fmtBytes(int b) {
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '$b B';
  }
}

// ================================================================
//  CARD — Event Log
// ================================================================
class _CardEventLog extends StatelessWidget {
  final List<PeripheralEvent> events;
  const _CardEventLog({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _BaseCard(
        child: Row(children: const [
          Icon(Icons.check_circle_outline_rounded, color: _cHijau, size: 18),
          SizedBox(width: 8),
          Text('Tidak ada event terbaru.', style: TextStyle(fontSize: 13, color: _cLabel)),
        ]),
      );
    }
    return _BaseCard(
      child: Column(
        children: events.asMap().entries.map((entry) {
          final i = entry.key;
          final ev = entry.value;
          return Column(
            children: [
              _EventRow(event: ev),
              if (i < events.length - 1)
                const Divider(height: 1, color: _cDivider, indent: 32),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final PeripheralEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(event.severityIcon, size: 16, color: event.severityColor),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _Badge(label: event.peripheral, color: _cBiru),
              const SizedBox(width: 6),
              _Badge(label: event.severity, color: event.severityColor),
              const Spacer(),
              if (event.waktuRtc != null)
                Text(event.waktuRtc!.length > 10
                    ? event.waktuRtc!.substring(11)
                    : event.waktuRtc!,
                    style: const TextStyle(fontSize: 10, color: _cAbu)),
            ]),
            const SizedBox(height: 4),
            Text(event.eventType,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _cDark)),
            if (event.keterangan != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(event.keterangan!,
                    style: const TextStyle(fontSize: 11, color: _cLabel)),
              ),
          ],
        )),
      ],
    ),
  );
}

// ================================================================
//  WIDGET HELPERS UMUM
// ================================================================

class _BaseCard extends StatelessWidget {
  final Widget child;
  const _BaseCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _cCard,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final IconData ikon;
  final Color    ikonColor;
  final String   judul;
  final Widget?  trailing;
  const _CardHeader({required this.ikon, required this.ikonColor,
    required this.judul, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ikonColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(ikon, size: 18, color: ikonColor),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(judul,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: _cDark))),
      if (trailing != null) trailing!,
    ]),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, color: _cDivider, indent: 0, endIndent: 0);
}

// badge kecil
class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3), width: 0.8),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

// chip dengan ikon + nilai
class _MetricChip extends StatelessWidget {
  final String   label, nilai;
  final Color    warna;
  final IconData ikon;
  const _MetricChip({required this.label, required this.nilai,
    required this.warna, required this.ikon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: warna.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: warna.withOpacity(0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(ikon, size: 12, color: warna),
          const SizedBox(width: 4),
          Expanded(child: Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: _cAbu))),
        ]),
        const SizedBox(height: 3),
        Text(nilai,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: warna)),
      ],
    ),
  );
}

// row info horizontal
class _InfoRow extends StatelessWidget {
  final IconData ikon;
  final String   label, nilai;
  final Color    warna;
  const _InfoRow({required this.ikon, required this.label,
    required this.nilai, required this.warna});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(ikon, size: 13, color: warna),
      const SizedBox(width: 6),
      Text('$label: ', style: const TextStyle(fontSize: 11, color: _cAbu)),
      Flexible(child: Text(nilai,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: warna),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}

// row mini dua kolom
class _MiniRow extends StatelessWidget {
  final String label, nilai;
  final Color  warna;
  const _MiniRow({required this.label, required this.nilai, required this.warna});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label: ',
        style: const TextStyle(fontSize: 11, color: _cAbu)),
    Flexible(child: Text(nilai,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: warna),
        overflow: TextOverflow.ellipsis)),
  ]);
}

// progress bar horizontal
class _ProgressBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color  warna;
  const _ProgressBar({required this.label, required this.pct,
    required this.warna});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: _cAbu)),
      const SizedBox(height: 4),
      Stack(children: [
        Container(height: 7,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4))),
        FractionallySizedBox(
          widthFactor: pct.clamp(0.0, 1.0),
          child: Container(height: 7,
              decoration: BoxDecoration(color: warna,
                  borderRadius: BorderRadius.circular(4))),
        ),
      ]),
    ],
  );
}

// track posisi stepper dengan marker target
class _PosisiTrack extends StatelessWidget {
  final double posisiPct, targetPct, posisiCm, targetCm;
  final Color  warna;
  const _PosisiTrack({required this.posisiPct, required this.targetPct,
    required this.posisiCm, required this.targetCm, required this.warna});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text('Posisi: ${posisiCm.toStringAsFixed(1)} cm',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: warna)),
        const Spacer(),
        Text('Target: ${targetCm.toStringAsFixed(1)} cm',
            style: const TextStyle(fontSize: 11, color: _cAbu)),
      ]),
      const SizedBox(height: 6),
      LayoutBuilder(builder: (ctx, box) {
        final w = box.maxWidth;
        return SizedBox(height: 16, child: Stack(children: [
          // Track bg
          Positioned(top: 5, left: 0, right: 0, child: Container(
              height: 6,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(3)))),
          // Progress fill
          Positioned(top: 5, left: 0,
              width: w * posisiPct.clamp(0.0, 1.0),
              child: Container(height: 6,
                  decoration: BoxDecoration(color: warna,
                      borderRadius: BorderRadius.circular(3)))),
          // Target marker
          Positioned(top: 0,
              left: (w * targetPct.clamp(0.0, 1.0) - 1).clamp(0, w - 2),
              child: Container(width: 2, height: 16,
                  decoration: BoxDecoration(
                      color: _cKuning.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(1)))),
          // Posisi marker (dot)
          Positioned(top: 3,
              left: (w * posisiPct.clamp(0.0, 1.0) - 5).clamp(0, w - 10),
              child: Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: warna,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)))),
        ]));
      }),
      const SizedBox(height: 2),
      Row(children: [
        const Text('Home (0 cm)',
            style: TextStyle(fontSize: 9, color: _cAbu)),
        const Spacer(),
        const Text('Batas (200 cm)',
            style: TextStyle(fontSize: 9, color: _cAbu)),
      ]),
    ],
  );
}

// skeleton placeholder
class _SkeletonCard extends StatelessWidget {
  final double minHeight;
  const _SkeletonCard({this.minHeight = 120});
  @override
  Widget build(BuildContext context) => _BaseCard(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _skBox(w: 36, h: 36, r: 10),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _skBox(w: 90, h: 10, r: 4),
              const SizedBox(height: 6),
              _skBox(w: 140, h: 13, r: 4),
            ]),
          ]),
          const SizedBox(height: 14),
          _skBox(w: double.infinity, h: 10, r: 4),
          const SizedBox(height: 7),
          _skBox(w: 200, h: 10, r: 4),
          const SizedBox(height: 14),
          Row(children: List.generate(3, (i) => Expanded(child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: _skBox(w: double.infinity, h: 48, r: 10),
          )))),
        ],
      ),
    ),
  );
  static Widget _skBox({double? w, required double h, required double r}) =>
      Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F8),
          borderRadius: BorderRadius.circular(r),
        ),
      );
}


// ================================================================
//  INTEGRASI: Tombol "Detail Peripheral" di _CardRobotStatus
//  (Tambahkan snippet ini ke dalam _CardRobotStatus.build())
// ================================================================
//
//  Di bawah Row yang berisi _ChipStatus (motor, limit, koneksi),
//  tambahkan:
//
//  const SizedBox(height: 12),
//  SizedBox(
//    width: double.infinity,
//    child: OutlinedButton.icon(
//      onPressed: () => Navigator.push(
//        context,
//        MaterialPageRoute(
//          builder: (_) => HalamanPeripheralMonitoring(
//            deviceId: data!.deviceId,
//          ),
//        ),
//      ),
//      icon: const Icon(Icons.developer_board_rounded, size: 16),
//      label: const Text('Detail Peripheral'),
//      style: OutlinedButton.styleFrom(
//        foregroundColor: const Color(0xFF0EA5E9),
//        side: const BorderSide(color: Color(0xFF0EA5E9), width: 0.8),
//        padding: const EdgeInsets.symmetric(vertical: 10),
//        shape: RoundedRectangleBorder(
//          borderRadius: BorderRadius.circular(12),
//        ),
//      ),
//    ),
//  ),
//
// ================================================================
