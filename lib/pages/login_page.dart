import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String selectedRole = "Client";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Daftar Akun TrimaJadi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ["Client", "Seller"].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
              onChanged: (value) => setState(() => selectedRole = value!),
              decoration: const InputDecoration(labelText: "Tipe Akun", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F)),
                onPressed: () {
                  // Simpan ke Model
                  UserData.name = nameController.text;
                  UserData.email = emailController.text;
                  UserData.role = selectedRole;

                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
                },
                child: const Text("Masuk", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}