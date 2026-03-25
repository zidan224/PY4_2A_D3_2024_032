import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterController extends ChangeNotifier {
  final String username; // Perbaikan: Tipe data String harus kapital
  int value = 0;
  int step = 1;
  int _backupValue = 0;
  List<String> history = [];

  // Constructor: Sekarang wajib menerima username saat diinisialisasi
  CounterController(this.username) {
    loadData();
  }

  // --- LOGIKA UTAMA ---

  void increment() {
    value += step;
    _updateHistory("Increment");
    saveData();
    notifyListeners();
  }

  void decrement() {
    value -= step;
    _updateHistory("Decrement");
    saveData();
    notifyListeners();
  }

  void reset() {
    if (value == 0) return;
    _backupValue = value;
    value = 0;
    _updateHistory("Reset");
    saveData();
    notifyListeners();
  }

  void undoReset() {
    value = _backupValue;
    _updateHistory("Undo Reset");
    saveData();
    notifyListeners();
  }

  void setStep(String input) {
    step = int.tryParse(input) ?? 1;
  }

  void _updateHistory(String action) {
    String time = DateTime.now().toString().substring(11, 16);
    // Sesuai Spesifikasi Tugas: "User admin menambah +5 pada jam 10:00"
    String logEntry = "User $username: $action $value (pada $time)";

    history.insert(0, logEntry);

    if (history.length > 5) {
      history.removeLast();
    }
  }

  // --- DATA PERSISTENCE DENGAN UNIQUE KEY ---

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    // Key dibuat unik dengan tambahan nama username
    await prefs.setInt('last_number_$username', value);
    await prefs.setStringList('history_log_$username', history);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Mengambil data spesifik milik user yang login
    value = prefs.getInt('last_number_$username') ?? 0;
    List<String> savedHistory =
        prefs.getStringList('history_log_$username') ?? [];

    if (savedHistory.length > 5) {
      history = savedHistory.sublist(0, 5);
    } else {
      history = savedHistory;
    }

    notifyListeners();
  }
}
