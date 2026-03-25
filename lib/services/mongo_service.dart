import 'dart:developer' as developer;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_032/features/logbook/models/log_model.dart';
import 'package:logbook_app_032/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;
  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) throw Exception("MONGODB_URI tidak ditemukan di .env");

      _db = await Db.create(dbUri);

      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception("Koneksi Timeout. Cek IP Whitelist atau Sinyal.");
        },
      );

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// READ: Filter berdasarkan TEAMID                                    // ← UBAH
  Future<List<LogModel>> getLogs(String teamId) async {
    // ← UBAH parameter
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId", // ← UBAH
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId)) // ← UBAH: username → teamId
          .toList();

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed for team $teamId - $e", // ← UBAH
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  /// CREATE
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());

      await LogHelper.writeLog(
        "SUCCESS: Data '${log.title}' milik ${log.username} disimpan",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// UPDATE
  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      await collection.update(
        where.id(
          ObjectId.fromHexString(log.id!),
        ), // ← UBAH: konversi String → ObjectId
        modify
            .set('title', log.title)
            .set('description', log.description)
            .set('date', log.date)
            .set('username', log.username)
            .set('authorId', log.authorId) // ← TAMBAH
            .set('teamId', log.teamId), // ← TAMBAH
      );

      await LogHelper.writeLog("SUCCESS: Data ${log.id} berhasil diupdate");
    } catch (e, stackTrace) {
      developer.log(
        'Error saat memperbarui MongoDB',
        name: 'service.mongo',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// DELETE
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));
      await LogHelper.writeLog("SUCCESS: ID $id terhapus");
    } catch (e) {
      await LogHelper.writeLog("ERROR: Delete Failed - $e", level: 1);
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
    }
  }
}
