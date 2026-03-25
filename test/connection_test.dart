import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Ganti 'logbook_app_001' dengan nama folder proyek kamu (cek di pubspec.yaml)
import 'package:logbook_app_032/services/mongo_service.dart';
import 'package:logbook_app_032/helpers/log_helper.dart';

void main() {
  const String sourceFile = "connection_test.dart";

  // Setup awal sebelum tes dijalankan
  setUpAll(() async {
    // Memuat konfigurasi dari file .env di root folder
    await dotenv.load(fileName: ".env");
  });

  test(
    'Memastikan koneksi ke MongoDB Atlas berhasil via MongoService',
    () async {
      final mongoService = MongoService();

      // Memulai pencatatan log tes
      await LogHelper.writeLog(
        "--- START CONNECTION TEST ---",
        source: sourceFile,
      );

      try {
        // 1. Mencoba menghubungkan aplikasi ke MongoDB Atlas
        await mongoService.connect();

        // 2. Validasi: Pastikan URI di .env tidak kosong
        expect(dotenv.env['MONGODB_URI'], isNotNull);

        await LogHelper.writeLog(
          "SUCCESS: Koneksi Atlas Terverifikasi",
          source: sourceFile,
          level: 2, // INFO (Warna Hijau di terminal)
        );
      } catch (e) {
        // Mencatat log jika terjadi kegagalan
        await LogHelper.writeLog(
          "ERROR: Kegagalan koneksi - $e",
          source: sourceFile,
          level: 1, // ERROR (Warna Merah di terminal)
        );
        fail("Koneksi gagal: $e");
      } finally {
        // 3. Selalu tutup koneksi agar tidak membebani cluster Atlas
        await mongoService.close();
        await LogHelper.writeLog("--- END TEST ---", source: sourceFile);
      }
    },
  );
}
