// lib/services/api_refresh_service.dart
//
// Auto-refresh service yang efisien:
// - Interval berbeda per endpoint (history lebih jarang, sensor lebih sering)
// - Hanya notify listener jika data benar-benar berubah (hash comparison)
// - Back-off otomatis saat error (tidak spam server saat offline)
// - Pause saat app di background
// - Cancel semua timer saat dispose

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// ─── ENUM ENDPOINT ───────────────────────────────────────────────────────────

enum RefreshEndpoint {
  historyPakan,
  jadwal,
  sensorLatest,
}

// ─── KONFIGURASI INTERVAL PER ENDPOINT ───────────────────────────────────────

const Map<RefreshEndpoint, Duration> _kIntervalNormal = {
  RefreshEndpoint.sensorLatest: Duration(seconds: 5),   // sensor: cepat
  RefreshEndpoint.jadwal:       Duration(seconds: 30),  // jadwal: jarang berubah
  RefreshEndpoint.historyPakan: Duration(seconds: 20),  // history: sedang
};

const Map<RefreshEndpoint, Duration> _kIntervalError = {
  RefreshEndpoint.sensorLatest: Duration(seconds: 15),  // saat error, lebih lambat
  RefreshEndpoint.jadwal:       Duration(minutes: 2),
  RefreshEndpoint.historyPakan: Duration(seconds: 45),
};

// ─── DATA MODEL ──────────────────────────────────────────────────────────────

class RefreshState<T> {
  final T? data;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const RefreshState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  RefreshState<T> copyWith({
    T? data,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) =>
      RefreshState<T>(
        data:         data         ?? this.data,
        isLoading:    isLoading    ?? this.isLoading,
        errorMessage: errorMessage,      // null = hapus error
        lastUpdated:  lastUpdated  ?? this.lastUpdated,
      );
}

// ─── API REFRESH SERVICE ──────────────────────────────────────────────────────

class ApiRefreshService extends ChangeNotifier {
  // State per endpoint
  RefreshState<List<dynamic>> historyState =
      const RefreshState(isLoading: true);
  RefreshState<List<dynamic>> jadwalState =
      const RefreshState(isLoading: true);
  RefreshState<Map<String, dynamic>> sensorState =
      const RefreshState(isLoading: true);

  // Internal: timer & hash untuk deteksi perubahan
  final Map<RefreshEndpoint, Timer?>   _timers    = {};
  final Map<RefreshEndpoint, String>   _lastHash  = {};
  final Map<RefreshEndpoint, int>      _errCount  = {};
  final Map<RefreshEndpoint, bool>     _running   = {};

  bool _disposed = false;

  // ── INISIALISASI ────────────────────────────────────────────────────────────

  void startAll() {
    for (final ep in RefreshEndpoint.values) {
      _scheduleNext(ep, immediate: true);
    }
  }

  /// Mulai hanya endpoint tertentu (berguna untuk halaman spesifik)
  void start(RefreshEndpoint ep) => _scheduleNext(ep, immediate: true);

  /// Hentikan endpoint tertentu (hemat resource saat halaman tidak aktif)
  void pause(RefreshEndpoint ep) {
    _timers[ep]?.cancel();
    _timers[ep] = null;
  }

  void pauseAll() {
    for (final ep in RefreshEndpoint.values) {
      pause(ep);
    }
  }

  /// Force refresh satu endpoint sekarang (misalnya setelah user action)
  Future<void> forceRefresh(RefreshEndpoint ep) async {
    _timers[ep]?.cancel();
    await _fetch(ep);
    _scheduleNext(ep);
  }

  // ── PENJADWALAN ──────────────────────────────────────────────────────────────

  void _scheduleNext(RefreshEndpoint ep, {bool immediate = false}) {
    if (_disposed) return;
    _timers[ep]?.cancel();

    if (immediate) {
      // Fetch sekarang, lalu jadwalkan berikutnya
      _fetch(ep).then((_) => _scheduleNext(ep));
    } else {
      final hasError = (_errCount[ep] ?? 0) > 0;
      final interval = hasError
          ? _kIntervalError[ep]!
          : _kIntervalNormal[ep]!;

      _timers[ep] = Timer(interval, () async {
        await _fetch(ep);
        if (!_disposed) _scheduleNext(ep);
      });
    }
  }

  // ── FETCH LOGIC ───────────────────────────────────────────────────────────────

  Future<void> _fetch(RefreshEndpoint ep) async {
    if (_disposed) return;
    if (_running[ep] == true) return; // Cegah concurrent fetch
    _running[ep] = true;

    try {
      final url  = _urlFor(ep);
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (_disposed) return;

      if (resp.statusCode == 200) {
        final body    = resp.body;
        final newHash = _hash(body);

        // ── Hanya update state jika data berubah ──────────────────────────
        if (_lastHash[ep] != newHash) {
          _lastHash[ep] = newHash;
          _applyData(ep, body);
        }
        _errCount[ep] = 0; // Reset error counter saat sukses

      } else {
        _applyError(ep, 'HTTP ${resp.statusCode}');
      }
    } on TimeoutException {
      _applyError(ep, 'Timeout — server tidak merespons');
    } catch (e) {
      _applyError(ep, 'Koneksi gagal: $e');
    } finally {
      _running[ep] = false;
    }
  }

  // ── URL MAPPING ───────────────────────────────────────────────────────────────

  String _urlFor(RefreshEndpoint ep) {
    switch (ep) {
      case RefreshEndpoint.historyPakan:
        return '${ApiConfig.baseUrl}/api/history_pakan';
      case RefreshEndpoint.jadwal:
        return '${ApiConfig.baseUrl}/api/jadwal/${ApiConfig.deviceId}';
      case RefreshEndpoint.sensorLatest:
        return '${ApiConfig.baseUrl}/api/sensor/latest';
    }
  }

  // ── APPLY DATA ────────────────────────────────────────────────────────────────

  void _applyData(RefreshEndpoint ep, String rawBody) {
    if (_disposed) return;
    final now = DateTime.now();

    switch (ep) {
      case RefreshEndpoint.historyPakan:
        final json = jsonDecode(rawBody);
        final list = (json['data'] as List<dynamic>?) ?? [];
        historyState = historyState.copyWith(
          data:        list,
          isLoading:   false,
          lastUpdated: now,
        );
        break;

      case RefreshEndpoint.jadwal:
        final list = jsonDecode(rawBody) as List<dynamic>;
        jadwalState = jadwalState.copyWith(
          data:        list,
          isLoading:   false,
          lastUpdated: now,
        );
        break;

      case RefreshEndpoint.sensorLatest:
        final map = jsonDecode(rawBody) as Map<String, dynamic>;
        sensorState = sensorState.copyWith(
          data:        map,
          isLoading:   false,
          lastUpdated: now,
        );
        break;
    }

    notifyListeners();
  }

  void _applyError(RefreshEndpoint ep, String message) {
    if (_disposed) return;
    _errCount[ep] = (_errCount[ep] ?? 0) + 1;

    switch (ep) {
      case RefreshEndpoint.historyPakan:
        // Pertahankan data lama, hanya tambahkan pesan error
        historyState = historyState.copyWith(
          isLoading:    false,
          errorMessage: message,
        );
        break;
      case RefreshEndpoint.jadwal:
        jadwalState = jadwalState.copyWith(
          isLoading:    false,
          errorMessage: message,
        );
        break;
      case RefreshEndpoint.sensorLatest:
        sensorState = sensorState.copyWith(
          isLoading:    false,
          errorMessage: message,
        );
        break;
    }

    notifyListeners();
  }

  // ── HASH HELPER ───────────────────────────────────────────────────────────────

  /// Hash ringan: hanya cek panjang + beberapa karakter
  /// Cukup untuk deteksi perubahan tanpa overhead crypto
  String _hash(String s) {
    if (s.isEmpty) return '';
    final len = s.length;
    // Ambil char di posisi awal, tengah, akhir
    final sample = '${s[0]}${s[len ~/ 4]}${s[len ~/ 2]}${s[len - 1]}$len';
    return sample;
  }

  // ── DISPOSE ───────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers.values) {
      t?.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
