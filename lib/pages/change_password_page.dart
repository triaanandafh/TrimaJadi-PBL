import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Controller untuk membaca inputan
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Status loading untuk tombol
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // FUNGSI UBAH PASSWORD (DENGAN KONFIRMASI)
  Future<void> _updatePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validasi Input Kosong
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Validasi Minimal Karakter
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru minimal 6 karakter'), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. Validasi Kecocokan Password Baru
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("Sesi pengguna tidak valid.");
      }

      // 4. Verifikasi Password Lama (Silently Login)
      try {
        await supabase.auth.signInWithPassword(
          email: user.email!,
          password: oldPassword,
        );
      } catch (e) {
        // Jika login gagal, berarti password lama yang dimasukkan SALAH
        throw Exception("Password lama yang Anda masukkan salah.");
      }

      // 5. Update ke Password Baru
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Membersihkan teks error bawaan agar lebih rapi dibaca
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // FUNGSI LUPA PASSWORD (KIRIM EMAIL RESET)
  Future<void> _forgotPassword() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null && user.email != null) {
        // Mengirim email reset password
        await supabase.auth.resetPasswordForEmail(user.email!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link reset password telah dikirim ke email Anda.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim email reset: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left), 
          onPressed: () => Navigator.pop(context)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ubah Password', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
      ),
      // Menggunakan SingleChildScrollView agar tidak error keyboard overlap
      body: SingleChildScrollView( 
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            // Kolom Password Lama
            _buildTextField(
              label: 'Password Lama', 
              icon: Icons.lock_outline,
              controller: _oldPasswordController,
            ),
            
            // Tombol Lupa Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text(
                  'Lupa Password?',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Kolom Password Baru
            _buildTextField(
              label: 'Password Baru', 
              icon: Icons.lock_reset,
              controller: _newPasswordController,
            ),
            const SizedBox(height: 20),
            
            // Kolom Konfirmasi
            _buildTextField(
              label: 'Konfirmasi Password', 
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
            ),
            
            const SizedBox(height: 50),
            _buildButton('Simpan Perubahan'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: BorderSide.none
            ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
        onPressed: _isLoading ? null : _updatePassword,
        child: _isLoading
            ? const SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
