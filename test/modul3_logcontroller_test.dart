import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart'; // Library untuk mock hive
import 'package:hive/hive.dart';
import 'package:logbook_app_032/features/logbook/models/log_model.dart';
import 'package:logbook_app_032/features/logbook/log_controller.dart';

void main() {
  late LogController logController;

  setUp(() async {
    // 1. Inisialisasi Hive khusus testing (di memori)
    await setUpTestHive();

    // REGISTER ADAPTER DI SINI (PENTING!)
    // Pastikan angka di isAdapterRegistered sesuai dengan typeId: 0
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LogModelAdapter());
    }

    await Hive.openBox<LogModel>('offline_logs');

    // 2. Inisialisasi Controller
    logController = LogController(
      username: "admin",
      teamId: "TEAM_032",
      role: "Admin",
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('LogController - CRUD & Logic Tests', () {
    test('Initial State: Log harus kosong saat pertama kali load', () {
      expect(logController.filteredLogs.value, isEmpty);
    });

    test('Create: addLog harus menambah data ke filteredLogs', () async {
      await logController.addLog(
        "Test Judul",
        "Deskripsi Testing",
        "General",
        true,
      );

      // Cek apakah data bertambah di list
      expect(logController.filteredLogs.value.length, 1);
      expect(logController.filteredLogs.value.first.title, "Test Judul");
    });

    test(
      'Visibility: User tidak boleh melihat log privat orang lain',
      () async {
        // Simulasi controller untuk user biasa
        final anggotaController = LogController(
          username: "user_biasa",
          teamId: "TEAM_032",
          role: "Anggota",
        );

        // Tambahkan log privat oleh Admin (secara manual ke box)
        final box = Hive.box<LogModel>('offline_logs');
        await box.add(
          LogModel(
            title: "Rahasia Negara",
            description: "Sangat rahasia",
            date: "2023-10-10",
            username: "admin",
            authorId: "admin",
            teamId: "TEAM_032",
            authorRole: "Admin",
            isPublic: false, // PRIVAT
          ),
        );

        await anggotaController.loadLogs();

        // Anggota tidak boleh melihat log privat admin
        expect(anggotaController.filteredLogs.value, isEmpty);
      },
    );

    test('Search: filterLogs harus menyaring data berdasarkan judul', () async {
      await logController.addLog("Apel", "Makan apel", "Food", true);
      await logController.addLog("Jeruk", "Minum jeruk", "Drink", true);

      logController.filterLogs("Apel");
      expect(logController.filteredLogs.value.length, 1);
      expect(logController.filteredLogs.value.first.title, "Apel");
    });
  });
}
