import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(radius: 35, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 40, color: Colors.white)),
                const SizedBox(width: 15),
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
          const Divider(),
          const ListTile(leading: Icon(Icons.person_outline), title: Text("Edit Profil"), trailing: Icon(Icons.chevron_right)),
          const ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text("Keluar Akun", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}