// test/module1_counter_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_032/features/logbook/counter_controller.dart';

void main() {
  dynamic actual, expected;

  group('Module 1 - CounterController (with storage and step)', () {
    late CounterController controller;
    const username = "admin";

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      controller = CounterController(username);
      await Future.delayed(Duration.zero); // Tunggu loadData selesai
    });

    // 1. Test Nilai Awal
    test('initial value should be 0', () {
      expect(controller.value, 0);
    });

    // 2. Test Perubahan Step
    test('setStep should change step value from string', () {
      controller.setStep("5");
      expect(controller.step, 5);
    });

    // 3. Test Step Tidak Valid (Fallback)
    test('setStep should default to 1 if input is invalid string', () {
      controller.setStep("abc");
      expect(controller.step, 1);
    });

    // 4. Test Increment (Tambah)
    test('increment should increase counter based on step', () {
      controller.setStep("2");
      controller.increment();
      expect(controller.value, 2);
    });

    // 5. Test Decrement (Kurang) - Sesuai gambar: Berkurang normal
    test('decrement should decrease counter based on step', () {
      controller.setStep("5");
      controller.increment(); // value = 5
      controller.decrement(); // value = 0
      expect(controller.value, 0);
    });

    // 6. Test Decrement Dua Kali (Batas Bawah) - Sesuai Gambar Anda
    test('decrement twice should not go below zero', () {
      controller.setStep("2");
      controller.increment(); // value = 2
      controller.decrement(); // value = 0
      controller.decrement(); // value tetap 0 (tidak boleh negatif)
      expect(controller.value, 0);
    });

    // 7. Test Reset
    test('reset should set counter back to zero', () {
      controller.setStep("10");
      controller.increment();
      controller.reset();
      expect(controller.value, 0);
    });

    // 9. Test History Limit (Max 5)
    test('history should not exceed 5 items (FIFO)', () {
      for (int i = 0; i < 7; i++) {
        controller.increment();
      }
      expect(controller.history.length, 5);
    });

    // 10. Test SharedPreferences (Data Persistence)
    test('counter should persist using SharedPreferences', () async {
      controller.setStep("3");
      controller.increment(); // value = 3
      await controller.saveData();

      final newController = CounterController(username);
      await newController.loadData();

      expect(newController.value, 3);
    });
  });
}
