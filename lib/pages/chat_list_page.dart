import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String formatChatTime(String? timestampStr) {
    // Logika sederhana untuk memformat waktu (bisa dikembangkan lebih lanjut)
    if (timestampStr == null) return "";
    try{
      DateTime date =DateTime.parse(timestampStr).toLocal();
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime chatDay = DateTime(date.year, date.month, date.day);

      final difference = today.difference(chatDay).inDays;
      if (difference == 0) {
        return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } else if (difference == 1) {
        return "Kemarin";
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final String myId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Warna background abu muda
      body: Stack(
        children: [
          // 1. HEADER BIRU (Background)
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A237E), // Deep Blue (Profil kamu)
                  Color(0xFF283593), // Indigo yang lebih terang
                  Color(0xFF3949AB), // Light Indigo (Orderan kamu)
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase.from('chats').stream(primaryKey: ['id']).eq('user_id', myId),
                  builder: (context, snapshot) {
                    final int chatCount = snapshot.data?.length ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(left: 25, bottom: 20),
                      child: Text(
                        "$chatCount percakapan aktif",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 10),
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
                    child: Column(
                      children: [
                        
                        // PERUBAHAN UTAMA: Kolom Searching ala WhatsApp
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Cari percakapan...",
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF2F5FA), // Warna abu-biru soft agar kontras dengan card putih
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none, // Menghilangkan garis border luar
                              ),
                            ),
                          ),
                        ),
                    Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: supabase.from('chats').stream(primaryKey: ['id']).eq('user_id', myId).order('time', ascending: false),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Belum ada obrolan aktif',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            );
                          }
                          final chatList = snapshot.data!;

                          // lOGIKA fILTERING CHAT BERDASARKAN NAMA DAN PESAN TERAKHIR
                          final filteredChatList = _searchQuery.isEmpty
                              ? chatList
                              : chatList.where((chat) {
                                  final name = (chat['name'] as String).toLowerCase();
                                  final lastMessage = (chat['last_message'] as String).toLowerCase();
                                  final query = _searchQuery.toLowerCase();
                                  return name.contains(query) || lastMessage.contains(query);
                                }).toList();

                          if (filteredChatList.isEmpty) {
                            return const Center(
                              child: Text('Tidak ada percakapan yang cocok',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            );
                          }

                          return ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: filteredChatList.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                            itemBuilder: (context, index) {
                              final chat = filteredChatList[index];
                              return ChatItem(
                                name: chat['name'] as String,
                                lastMessage: chat['last_message'] as String,
                                time: formatChatTime(chat['time'] as String?),
                                unread: chat['unread'] as int,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
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