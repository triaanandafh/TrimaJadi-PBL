import 'package:flutter/material.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Warna background abu muda
      body: Stack(
        children: [
          // 1. HEADER BIRU (Background)
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1A43BF), // Warna biru utama kamu
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 2. KONTEN UTAMA
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigasi Atas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const Text(
                        "Chat",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 25, bottom: 20),
                  child: Text(
                    "3 percakapan aktif",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),

                // 3. DAFTAR CHAT (Card Putih)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children:  [
                          ChatItem(
                            name: "Budi Designer",
                            lastMessage: "Siap kak, revisinya sudah saya kirim",
                            time: "10:30",
                            unread: 2,
                          ),
                          Divider(height: 1, indent: 80),
                          ChatItem(
                            name: "Andi Programmer",
                            lastMessage: "Website nya sudah fix ya",
                            time: "09:10",
                          ),
                          Divider(height: 1, indent: 80),
                          ChatItem(
                            name: "Siti Tutor",
                            lastMessage: "Jadwal besok jadi ya",
                            time: "Kemarin",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  // Fungsi pembantu untuk mengambil inisial (Contoh: Budi Designer -> BD)
  String getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    if (names.length >= 2) {
      initials = names[0][0] + names[1][0];
    } else {
      initials = names[0][0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        // Pastikan file chat_page.dart kamu sudah menerima parameter 'name'
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ChatPage(name: name))
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF3B5998),
            child: Text(
              getInitials(name),
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          // Dot Indikator Status (Oranye)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFE68C3A), 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: unread > 0 ? const Color(0xFFE68C3A) : Colors.grey,
              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            // Badge Notifikasi jika ada pesan yang belum dibaca
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE68C3A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread.toString(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}