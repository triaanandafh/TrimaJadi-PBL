import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(radius: 35, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 40, color: Colors.white)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DATA DARI LOGIN
                    Text(UserData.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(UserData.email, style: const TextStyle(color: Colors.grey)),
                    Text("Role: ${UserData.role}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          _menuItem(Icons.edit_outlined, "Edit Profil"),
          const Divider(indent: 20, endIndent: 20),
          _menuItem(Icons.lock_outline, "Ubah Password"),
          const Divider(indent: 20, endIndent: 20),
          _menuItem(Icons.notifications, "Atur Notifikasi"),
          const Divider(indent: 20, endIndent: 20),
          _menuItem(Icons.logout, "Keluar Akun", textColor: Colors.red),
        ],
      ),
    );
  }

  // Tambahkan {Color? textColor} sebagai parameter opsional
Widget _menuItem(IconData icon, String title, {Color? textColor}) {
  return ListTile(
    leading: Icon(
      icon, 
      // Jika textColor ada, pakai itu. Jika tidak, pakai abu-abu.
      color: textColor ?? Colors.grey[700], 
    ),
    title: Text(
      title, 
      style: TextStyle(
        fontWeight: FontWeight.w500,
        // Jika textColor ada, pakai itu. Jika tidak, pakai hitam.
        color: textColor ?? Colors.black87, 
      ),
    ),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    onTap: () {
      if (title == "Keluar Akun") {
        // Tambahkan logika logout di sini
      }
    },
  );
}
}