import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_032/features/logbook/models/log_model.dart';
import 'package:logbook_app_032/services/mongo_service.dart';
import 'package:logbook_app_032/helpers/log_helper.dart';
import 'dart:async';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  late Box<LogModel> _offlineBox; // Hive box untuk offline logs
  final MongoService _mongoService = MongoService();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isSyncing = false;
  bool _lastConnected = false;

  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  /// Inisialisasi service
  Future<void> initialize() async {
    _offlineBox = Hive.box<LogModel>('offline_logs');

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _lastConnected =
        connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    // Monitor perubahan konektivitas
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final isConnected =
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);

      // Jika baru terhubung kembali (dari offline → online)
      if (isConnected && !_lastConnected) {
        LogHelper.writeLog(
          "CONNECTION: Internet kembali aktif, memulai auto-sync...",
          source: "offline_sync_service.dart",
          level: 2,
        );
        syncOfflineData();
      }

      _lastConnected = isConnected;
    });

    await LogHelper.writeLog(
      "OfflineSyncService: Initialized (Connected: $_lastConnected)",
      source: "offline_sync_service.dart",
      level: 3,
    );
  }

  /// 🔄 Sinkronkan semua data offline ke MongoDB
  Future<void> syncOfflineData() async {
    if (_isSyncing || _offlineBox.isEmpty) return;

    _isSyncing = true;
    try {
      final offlineLogs = _offlineBox.values.toList();

      await LogHelper.writeLog(
        "SYNC: Memulai auto-sync ${offlineLogs.length} data offline ke cloud...",
        source: "offline_sync_service.dart",
        level: 2,
      );

      int successCount = 0;
      List<int> successIndices = [];

      for (int i = 0; i < offlineLogs.length; i++) {
        try {
          await _mongoService.insertLog(offlineLogs[i]);
          successCount++;
          successIndices.add(i);

          await LogHelper.writeLog(
            "SYNC ✓: '${offlineLogs[i].title}' berhasil disinkronkan ke cloud",
            source: "offline_sync_service.dart",
            level: 2,
          );
        } catch (e) {
          await LogHelper.writeLog(
            "SYNC ✗: Gagal sinkronkan '${offlineLogs[i].title}' - $e",
            source: "offline_sync_service.dart",
            level: 1,
          );
        }
      }

      // Hapus yang BERHASIL dari Hive cache (dari belakang untuk avoid index shift)
      for (int i = successIndices.length - 1; i >= 0; i--) {
        final successIndex = successIndices[i];
        if (successIndex < _offlineBox.length) {
          await _offlineBox.deleteAt(successIndex);
        }
      }

      await LogHelper.writeLog(
        "SYNC COMPLETE: $successCount berhasil disimpan ke cloud, ${offlineLogs.length - successCount} akan dicoba ulang",
        source: "offline_sync_service.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "SYNC ERROR: $e",
        source: "offline_sync_service.dart",
        level: 1,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Tutup service
  Future<void> dispose() async {
    await _connectivitySubscription.cancel();
  }
}
