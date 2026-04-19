import 'package:flutter/material.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Ubah Password', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildTextField(label: 'Password Baru', icon: Icons.lock_outline),
            const SizedBox(height: 20),
            _buildTextField(label: 'Konfirmasi Password', icon: Icons.lock_outline),
            const Spacer(),
            _buildButton('Simpan'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: () {},
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}
