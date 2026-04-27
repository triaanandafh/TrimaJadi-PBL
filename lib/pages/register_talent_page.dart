import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterTalentPage extends StatefulWidget {
  const RegisterTalentPage({super.key});

  @override
  State<RegisterTalentPage> createState() => _RegisterTalentPageState();
}

class _RegisterTalentPageState extends State<RegisterTalentPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  final nimController = TextEditingController();
  final universityController = TextEditingController();
  final majorController = TextEditingController();

  final skillController = TextEditingController();
  final descController = TextEditingController();
  final cvController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    nimController.dispose();
    universityController.dispose();
    majorController.dispose();
    skillController.dispose();
    descController.dispose();
    cvController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi data wajib'),
        ),
      );
      return;
    }

    await AuthService.register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      role: "talent",
    );

    if (!context.mounted) return;

    Navigator.pop(context, true);
  }

  Widget buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                      'Daftar sebagai Talent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              sectionTitle("Data Akun"),
              const SizedBox(height: 15),

              buildInputField(
                label: "Nama Lengkap",
                icon: Icons.person_outline,
                controller: nameController,
              ),
              const SizedBox(height: 15),

              buildInputField(
                label: "E-mail",
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              const SizedBox(height: 15),

              buildInputField(
                label: "Password",
                icon: Icons.lock_outline,
                controller: passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 15),

              buildInputField(
                label: "Nomor Telepon",
                icon: Icons.phone_outlined,
                controller: phoneController,
              ),

              const SizedBox(height: 25),

              sectionTitle("Data Akademik"),
              const SizedBox(height: 15),

              buildInputField(
                label: "NIM",
                icon: Icons.badge_outlined,
                controller: nimController,
              ),
              const SizedBox(height: 15),

              buildInputField(
                label: "Universitas",
                icon: Icons.school_outlined,
                controller: universityController,
              ),
              const SizedBox(height: 15),

              buildInputField(
                label: "Jurusan / Program Studi",
                icon: Icons.menu_book_outlined,
                controller: majorController,
              ),

              const SizedBox(height: 25),

              sectionTitle("Data Profesional"),
              const SizedBox(height: 15),

              buildInputField(
                label: "Skill",
                icon: Icons.workspace_premium_outlined,
                controller: skillController,
              ),
              const SizedBox(height: 15),

              buildInputField(
                label: "Deskripsi Diri",
                icon: Icons.description_outlined,
                controller: descController,
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              buildInputField(
                label: "CV / Portfolio",
                icon: Icons.folder_open_outlined,
                controller: cvController,
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE88A2F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Masuk',
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
      ),
    );
  }
}