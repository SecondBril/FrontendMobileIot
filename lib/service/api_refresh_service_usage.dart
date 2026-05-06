// ─────────────────────────────────────────────────────────────────────────────
// CARA PAKAI — ApiRefreshService
// ─────────────────────────────────────────────────────────────────────────────

// ══════════════════════════════════════════════════════════════════════════════
// 1. DAFTARKAN DI main.dart / provider setup
// ══════════════════════════════════════════════════════════════════════════════

/*
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiRefreshService()..startAll()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
*/

// ══════════════════════════════════════════════════════════════════════════════
// 2. HALAMAN HISTORY — hanya aktifkan endpoint yang dibutuhkan
// ══════════════════════════════════════════════════════════════════════════════

/*
class HalamanHistory extends StatefulWidget { ... }

class _HalamanHistoryState extends State<HalamanHistory>
    with WidgetsBindingObserver {               // ← untuk deteksi foreground/bg

  late final ApiRefreshService _svc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _svc = context.read<ApiRefreshService>();
    // Aktifkan hanya endpoint yang diperlukan halaman ini
    _svc.start(RefreshEndpoint.historyPakan);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Pause saat keluar halaman — hemat baterai & bandwidth
    _svc.pause(RefreshEndpoint.historyPakan);
    super.dispose();
  }

  // Pause saat app masuk background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _svc.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      _svc.start(RefreshEndpoint.historyPakan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ApiRefreshService>().historyState;

    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.errorMessage ?? 'Gagal memuat data'),
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

    return Column(
      children: [
        // Indikator waktu update terakhir
        if (state.lastUpdated != null)
          _LastUpdatedBar(time: state.lastUpdated!),

        // Tanda error ringan (data lama masih ditampilkan)
        if (state.errorMessage != null)
          _ErrorBanner(message: state.errorMessage!),

        Expanded(
          child: ListView.builder(
            itemCount: state.data!.length,
            itemBuilder: (context, i) => HistoryTile(data: state.data![i]),
          ),
        ),
      ],
    );
  }
}
*/

// ══════════════════════════════════════════════════════════════════════════════
// 3. HALAMAN JADWAL — dengan force-refresh setelah mutasi
// ══════════════════════════════════════════════════════════════════════════════

/*
// Setelah create/toggle/delete jadwal, panggil forceRefresh:
Future<void> _tambahJadwal() async {
  final berhasil = await JadwalApiService.createJadwal(waktu, porsi);
  if (berhasil && mounted) {
    // Langsung refresh tanpa tunggu interval berikutnya
    await context.read<ApiRefreshService>().forceRefresh(RefreshEndpoint.jadwal);
  }
}
*/

// ══════════════════════════════════════════════════════════════════════════════
// 4. WIDGET INDIKATOR (opsional, untuk UX)
// ══════════════════════════════════════════════════════════════════════════════

/*
class _LastUpdatedBar extends StatelessWidget {
  final DateTime time;
  const _LastUpdatedBar({required this.time});

  @override
  Widget build(BuildContext context) {
    final selisih = DateTime.now().difference(time).inSeconds;
    final teks = selisih < 5
        ? 'Baru saja diperbarui'
        : 'Update ${selisih}d lalu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.green.shade50,
      child: Text(
        teks,
        style: const TextStyle(fontSize: 11, color: Colors.green),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Koneksi terganggu — menampilkan data terakhir',
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
*/
