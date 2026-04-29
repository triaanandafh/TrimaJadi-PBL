import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Notifikasi",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // --- BODY ---
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ===== HARI INI =====
          _dateLabel("Hari ini"),

          _notifItem(
            icon: Icons.shopping_bag,
            color: Colors.orange,
            title: "Order Baru 🎉",
            subtitle: "Kamu mendapatkan order desain logo",
            time: "10:30",
          ),

          _notifItem(
            icon: Icons.chat,
            color: Colors.blue,
            title: "Pesan Baru",
            subtitle: "Client mengirim pesan",
            time: "09:10",
          ),

          const SizedBox(height: 20),

          // ===== KEMARIN =====
          _dateLabel("Kemarin"),

          _notifItem(
            icon: Icons.check_circle,
            color: Colors.green,
            title: "Order Selesai",
            subtitle: "Order kamu telah selesai",
            time: "Kemarin",
          ),

          _notifItem(
            icon: Icons.star,
            color: Colors.purple,
            title: "Review Baru",
            subtitle: "Client memberi rating 5⭐",
            time: "Kemarin",
          ),
        ],
      ),
    );
  }

  // ===== DATE LABEL =====
  Widget _dateLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ===== ITEM NOTIFIKASI =====
  Widget _notifItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [

          // ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 12),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // TIME
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}