import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budiono', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Budiono145@gmail.com', style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
          const Divider(thickness: 1),
          _buildMenuItem(context, Icons.person_outline, 'Edit Profil', const EditProfilePage()),
          _buildMenuItem(context, Icons.lock_outline, 'Ubah Password', const ChangePasswordPage()),
          _buildMenuItem(context, Icons.notifications_outlined, 'Notifikasi', null),
          _buildMenuItem(context, Icons.logout, 'Keluar Akun', null),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, Widget? targetPage) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black54),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (targetPage != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
