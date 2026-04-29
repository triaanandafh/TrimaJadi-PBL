import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'client_register_page.dart';
import '../pages/main_screen.dart';

class LoginClientPage extends StatefulWidget {
  const LoginClientPage({super.key});

  @override
  State<LoginClientPage> createState() => _LoginClientPageState();
}

class _LoginClientPageState extends State<LoginClientPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password wajib diisi'),
        ),
      );
      return;
    }

    bool success = await AuthService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!context.mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email atau password salah'),
        ),
      );
    }
  }

  Future<void> _goToRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterClientPage(),
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Berhasil',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Akun berhasil terdaftar',
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1A43BF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'Masuk sebagai Client',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Masuk untuk memantau progres tugas\natau cari bantuan baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildTextField(
                    controller: emailController,
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    showEye: true,
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE88A2F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? '),
                      GestureDetector(
                        onTap: _goToRegister,
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool showEye = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: Colors.grey,
            ),
            suffixIcon: showEye
                ? const Icon(
                    Icons.visibility_outlined,
                    color: Colors.grey,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}