import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ← TAMBAH
import 'package:logbook_app_032/features/logbook/models/log_model.dart'; // ← TAMBAH
import 'package:logbook_app_032/services/mongo_service.dart';
import 'package:logbook_app_032/services/offline_sync_service.dart'; // ← TAMBAH
import 'package:logbook_app_032/features/onboarding/onboarding_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Muat file .env
  await dotenv.load(fileName: ".env");

  // 2. Inisialisasi Hive                                                // ← TAMBAH
  await Hive.initFlutter(); // ← TAMBAH
  Hive.registerAdapter(LogModelAdapter()); // ← TAMBAH

  // ← FIX: Clear old cache saat upgrade (untuk data migration)
  try {
    final box = await Hive.openBox<LogModel>('offline_logs');
    // Jika ada data dengan isPublic null, clear semua untuk fresh start
    bool needsClear = box.values.any((log) => log.isPublic == null);
    if (needsClear) {
      await box.clear();
      print("Cache cleared: Data migration needed due to isPublic field");
    }
  } catch (e) {
    print("Error checking cache: $e");
  }

  // 3. Inisialisasi OfflineSyncService                                  // ← TAMBAH
  await OfflineSyncService().initialize(); // ← TAMBAH

  // 4. Inisialisasi koneksi MongoDB
  try {
    await MongoService().connect();
  } catch (e) {
    print("Koneksi gagal saat startup: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}
