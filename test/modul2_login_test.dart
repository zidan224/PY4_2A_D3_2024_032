// import 'package:test/modul2_login_test.dart';
// import 'package:nama_proyek_kamu/login_controller.dart'; // Sesuaikan path file
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_032/features/auth/login_controller.dart';

void main() {
  // Inisialisasi controller sebelum test dijalankan
  final loginController = LoginController();

  group('LoginController Unit Tests', () {
    test('Login harus berhasil dengan kredensial yang benar', () {
      bool result = loginController.login("admin", "123");
      expect(result, isTrue);
    });

    test('Login harus gagal jika password salah', () {
      bool result = loginController.login("admin", "salah_password");
      expect(result, isFalse);
    });

    test('Login harus gagal jika username tidak terdaftar', () {
      bool result = loginController.login("user_gaib", "123");
      expect(result, isFalse);
    });

    test('getRole harus mengembalikan role yang sesuai', () {
      expect(loginController.getRole("admin"), equals("Admin"));
      expect(loginController.getRole("asisten"), equals("Asisten"));
      expect(loginController.getRole("ketua"), equals("Ketua"));
    });

    test('getRole harus mengembalikan null jika user tidak ada', () {
      expect(loginController.getRole("siapa_ini"), isNull);
    });

    test('getTeamId harus selalu mengembalikan TEAM_032', () {
      expect(loginController.getTeamId(), equals('TEAM_032'));
    });

    test('getAvailableUsers harus mengembalikan semua username', () {
      List<String> users = loginController.getAvailableUsers();
      expect(users, containsAll(['admin', 'asisten', 'anggota', 'ketua']));
      expect(users.length, equals(4));
    });
  });
}
