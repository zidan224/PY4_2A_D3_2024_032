import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app_032/services/mongo_service.dart';
import 'package:logbook_app_032/services/offline_sync_service.dart';
import 'package:logbook_app_032/services/access_control_service.dart';
import 'package:logbook_app_032/features/logbook/models/log_model.dart';
import 'package:logbook_app_032/helpers/log_helper.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class LogController {
  List<LogModel> _allLogs = [];
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final String username;
  final String teamId;
  final String role;
  final MongoService _mongoService = MongoService();
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

  LogController({
    required this.username,
    required this.teamId,
    required this.role,
  });

  /// --- 1. READ: Offline-First + Role-Based Visibility ---
  Future<void> loadLogs() async {
    // Langkah 1: Tampilkan data lokal dulu (instan) dengan visibility filter
    _allLogs = _myBox.values.toList();
    filteredLogs.value = _applyVisibilityFilter(_allLogs);

    // Langkah 2: Sync dari Cloud di background
    try {
      final cloudData = await _mongoService.getLogs(teamId);
      if (cloudData.isNotEmpty) {
        await _myBox.clear();
        await _myBox.addAll(cloudData);

        _allLogs = cloudData;
        filteredLogs.value = _applyVisibilityFilter(_allLogs);
      }

      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal - $e",
        level: 2,
      );
    }
  }

  /// --- 2. CREATE: Instant Local + Background Cloud ---
  Future<void> addLog(
    String title,
    String desc,
    String category,
    bool isPublic,
  ) async {
    final String fullDescription = "[$category] $desc";

    final newLog = LogModel(
      id: null, // <--- UBAH JADI NULL (Pastikan model kamu mengizinkan null)
      title: title,
      description: fullDescription,
      date: DateTime.now().toString().split('.').first,
      username: username,
      authorId: username,
      teamId: teamId,
      authorRole: role,
      isPublic: isPublic,
    );

    // Simpan ke Hive (Status: Masih Offline karena ID null)
    await _myBox.add(newLog);
    _allLogs = _myBox.values.toList();
    filteredLogs.value = _applyVisibilityFilter(_allLogs);

    try {
      // Kirim ke MongoDB
      await _mongoService.insertLog(newLog);

      // Setelah sukses, panggil loadLogs agar data di Hive diperbarui
      // dengan data yang sudah punya ID resmi dari Atlas
      await loadLogs();
    } catch (e) {
      // Jika gagal (offline), data tetap di Hive dengan id = null (tetap Abu-abu)
    }
  }

  /// --- 3. UPDATE ---
  Future<void> updateLog(
    ObjectId id,
    String title,
    String desc,
    String category,
    bool isPublic,
  ) async {
    final String fullDescription = "[$category] $desc";
    try {
      final updatedLog = LogModel(
        id: id.oid,
        title: title,
        description: fullDescription,
        date: DateTime.now().toString().split('.').first,
        username: username,
        authorId: username,
        teamId: teamId,
        authorRole: role,
        isPublic: isPublic,
      );

      // ACTION 1: Update Hive dulu (instan)
      final index = _allLogs.indexWhere((log) => log.id == id.oid);
      if (index != -1) {
        await _myBox.putAt(index, updatedLog);
        _allLogs[index] = updatedLog;
        filteredLogs.value = _applyVisibilityFilter(_allLogs);
      }

      // ACTION 2: Sync ke MongoDB
      await _mongoService.updateLog(updatedLog);
      await LogHelper.writeLog(
        "CONTROLLER: Berhasil update data milik $username",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "CONTROLLER: Gagal update cloud, data lokal tersimpan - $e",
        level: 1,
      );
    }
  }

  /// --- 4. DELETE ---
  Future<void> removeLog(ObjectId id) async {
    try {
      // ACTION 1: Hapus dari Hive dulu (instan)
      final index = _allLogs.indexWhere((log) => log.id == id.oid);
      if (index != -1) {
        await _myBox.deleteAt(index);
        _allLogs.removeAt(index);
        filteredLogs.value = List.from(_allLogs);
      }

      // ACTION 2: Hapus dari MongoDB
      await _mongoService.deleteLog(id);
      await LogHelper.writeLog(
        "CONTROLLER: Data $id berhasil dihapus",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "CONTROLLER: Gagal hapus cloud, data lokal sudah dihapus - $e",
        level: 1,
      );
      _allLogs = _myBox.values.toList();
      filteredLogs.value = List.from(_allLogs);
    }
  }

  /// --- Fitur Search Lokal ---
  void filterLogs(String query) {
    if (query.isEmpty) {
      filteredLogs.value = _applyVisibilityFilter(_allLogs);
    } else {
      final filtered = _allLogs
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredLogs.value = _applyVisibilityFilter(filtered);
    }
  }

  /// --- Apply Role-Based Visibility Filter ---
  List<LogModel> _applyVisibilityFilter(List<LogModel> logs) {
    return logs.where((log) {
      final isSameAuthor = log.authorId == username;
      final authorRole = log.authorRole ?? AccessControlService.roleAnggota;
      final isPublic = log.isPublic ?? true;

      return AccessControlService.canViewLogWithPrivacy(
        role,
        authorRole,
        isSameAuthor,
        isPublic,
      );
    }).toList();
  }

  /// --- Manual Sync (bisa dipanggil saat pull-to-refresh) ---
  Future<void> syncWithCloud() async {
    await OfflineSyncService().syncOfflineData();
    await loadLogs();
  }
}
