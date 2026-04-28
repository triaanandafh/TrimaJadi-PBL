import 'package:flutter/material.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Chat",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          Icon(Icons.search, color: Colors.black87),
          const SizedBox(width: 15),
        ],
      ),

      // --- LIST CHAT ---
      body: ListView(
        children: const [
          ChatItem(
            name: "Budi Designer",
            lastMessage: "Siap kak, revisinya sudah saya kirim",
            time: "10:30",
            unread: 2,
          ),
          ChatItem(
            name: "Andi Programmer",
            lastMessage: "Website nya sudah fix ya",
            time: "09:10",
          ),
          ChatItem(
            name: "Siti Tutor",
            lastMessage: "Jadwal besok jadi ya",
            time: "Kemarin",
          ),
        ],
      ),
    );
  }
}

class ChatItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;

  const ChatItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(name: name),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            // FOTO PROFIL
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[700]),
            ),

            const SizedBox(width: 12),

            // NAMA & PESAN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // WAKTU & BADGE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 5),

                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE68C3A),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}