import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logbook_app_032/features/auth/login_controller.dart';
import 'package:logbook_app_032/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isPasswordVisible = false;
  int _failedAttempts = 0;
  bool _isButtonDisabled = false;

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password tidak boleh kosong!"),
        ),
      );
      return;
    }

    if (_controller.login(user, pass)) {
      _failedAttempts = 0;
      final role = _controller.getRole(user);
      final teamId = _controller.getTeamId();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LogView(username: user, role: role ?? 'Anggota', teamId: teamId),
        ),
      );
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        setState(() => _isButtonDisabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terlalu banyak percobaan. Tunggu 10 detik."),
          ),
        );
        Timer(const Duration(seconds: 10), () {
          setState(() {
            _isButtonDisabled = false;
            _failedAttempts = 0;
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Login Gagal! Sisa percobaan: ${3 - _failedAttempts}",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Dasar Background: Biru di Atas, Putih di Bawah
          Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                color: const Color(0xFF00B4D8), // Biru atas

                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "LOGBOOK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Aplikasi Pencatatan Harian",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: Container(color: Colors.white)),
            ],
          ),

          // 2. Card Login
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    const Text(
                      "LOGIN",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0077B6),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Input Username
                    TextField(
                      controller: _userController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        labelStyle: TextStyle(color: Colors.grey),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00B4D8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Input Password
                    TextField(
                      controller: _passController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00B4D8)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Tombol Login
                    GestureDetector(
                      onTap: _isButtonDisabled ? null : _handleLogin,
                      child: Container(
                        width:
                            200, // Lebar tombol disesuaikan agar lonjong seperti gambar
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: _isButtonDisabled
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF48CAE4),
                                    Color(0xFF0077B6),
                                  ],
                                ),
                          color: _isButtonDisabled ? Colors.grey : null,
                        ),
                        child: Center(
                          child: Text(
                            _isButtonDisabled ? "Locked" : "LOGIN",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
