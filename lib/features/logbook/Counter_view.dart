import 'package:flutter/material.dart';
import 'counter_controller.dart';
import 'package:logbook_app_032/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late CounterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CounterController(widget.username);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingView(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome, ${widget.username}",
          style: const TextStyle(fontSize: 18),
        ), // Ukuran teks appBar dikecilkan
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: _handleLogout,
          ),
        ],
        backgroundColor: const Color(0xFF00B4D8),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50, // Tinggi AppBar dikurangi
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan Angka (Step):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 45, // Tinggi textbox diperkecil
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelText: 'Step',
                      prefixIcon: const Icon(Icons.ads_click, size: 18),
                    ),
                    onChanged: (val) => _controller.setStep(val),
                  ),
                ),

                const SizedBox(height: 12),

                // Baris Tombol Aksi (Reset, -, +) - Ukuran Dikecilkan
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => _controller.value == 0
                              ? null
                              : _controller.reset(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              243,
                              82,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _controller.decrement(),
                      icon: const Icon(Icons.remove, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFCAF0F8),
                        foregroundColor: const Color(0xFF0077B6),
                        minimumSize: const Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _controller.increment(),
                      icon: const Icon(Icons.add, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(40, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Card Total Hitungan - Ukuran Lebih Ringkas
                const Center(
                  child: Text(
                    "Total Hitungan:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ), // Batas lebar card
                    child: Card(
                      elevation: 3,
                      color: const Color(0xFF00B4D8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 35,
                        ), // Padding vertikal dikurangi
                        child: Center(
                          child: Text(
                            '${_controller.value}',
                            style: const TextStyle(
                              fontSize:
                                  50, // Ukuran angka dikecilkan dari 80 ke 50
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(thickness: 1),
                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    "Riwayat Aktivitas:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _controller.history.length,
                  itemBuilder: (context, index) {
                    final String item = _controller.history[index];
                    bool isInc = item.contains("Increment");
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: isInc ? Colors.green.shade50 : Colors.red.shade50,
                      child: ListTile(
                        dense: true, // Membuat ListTile lebih ramping
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          isInc ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isInc ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        title: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
