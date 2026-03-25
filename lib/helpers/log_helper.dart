import 'dart:developer' as dev;
import 'package:intl/intl.dart'; // Digunakan untuk presisi waktu [cite: 234, 236]
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  /// Fungsi utama untuk menulis log ke konsol dan terminal
  static Future<void> writeLog(
    String message, {
    String source = "Unknown", // Menandakan file atau proses asal
    int level = 2, // Default level adalah INFO (2)
  }) async {
    // 1. Filter Konfigurasi berdasarkan file .env
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    // Jangan tampilkan log jika level melebihi konfigurasi atau file masuk daftar mute
    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      // 2. Format Waktu dan Gaya Tampilan
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      String label = _getLabel(level);
      String color = _getColor(level);

      // 3. Output ke VS Code Debug Console (Non-blocking)
      dev.log(message, name: source, time: DateTime.now(), level: level * 100);

      // 4. Output ke Terminal dengan warna (Agar mudah dibaca saat flutter run)
      // Format: [HH:mm:ss][LABEL][file_asal] -> Pesan
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  /// Memberikan label teks berdasarkan tingkat kepentingan log
  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR"; // Merah
      case 2:
        return "INFO"; // Hijau
      case 3:
        return "VERBOSE"; // Biru
      default:
        return "LOG";
    }
  }

  /// Memberikan kode warna ANSI untuk tampilan terminal
  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah (Error)
      case 2:
        return '\x1B[32m'; // Hijau (Info)
      case 3:
        return '\x1B[34m'; // Biru (Verbose)
      default:
        return '\x1B[0m'; // Reset Warna
    }
  }
}
