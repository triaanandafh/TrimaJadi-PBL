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
    if (timestampStr == null || timestampStr.isEmpty) return "";
    try {
      DateTime date = DateTime.parse(timestampStr).toLocal();
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
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          // HEADER BIRU
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                  Color(0xFF3949AB),
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

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Obrolan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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
                  stream: supabase
                      .from('chat_messages')
                      .stream(primaryKey: ['id'])
                      .map((data) => data
                          .where((msg) =>
                              msg['sender_id'] == myId ||
                              msg['receiver_id'] == myId)
                          .toList()),
                  builder: (context, snapshot) {
                    // Hitung unique partner
                    final Set<String> partners = {};
                    for (final msg in snapshot.data ?? []) {
                      final partner = msg['sender_id'] == myId
                          ? msg['receiver_id']
                          : msg['sender_id'];
                      if (partner != null) partners.add(partner.toString());
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 25, bottom: 20),
                      child: Text(
                        "${partners.length} percakapan aktif",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

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
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.grey.shade500),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF2F5FA),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
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
                              stream: supabase
                                  .from('chat_messages')
                                  .stream(primaryKey: ['id'])
                                  .order('created_at', ascending: false),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final allMessages = snapshot.data ?? [];

                                if (allMessages.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Belum ada obrolan aktif',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                }

                                // Ambil pesan terbaru dari setiap unique conversation
                                final Map<String, Map<String, dynamic>> conversationMap = {};

                                for (final msg in allMessages) {
                                  final senderId = msg['sender_id']?.toString() ?? '';
                                  final receiverId = msg['receiver_id']?.toString() ?? '';

                                  // Hanya tampilkan percakapan yang melibatkan user ini
                                  if (senderId != myId && receiverId != myId) continue;

                                  // Buat key unik untuk pasangan ini (urutan tidak penting)
                                  final List<String> pair = [senderId, receiverId]..sort();
                                  final String key = pair.join('_');

                                  // Hanya simpan pesan terbaru (stream sudah descending)
                                  if (!conversationMap.containsKey(key)) {
                                    conversationMap[key] = msg;
                                  }
                                }

                                if (conversationMap.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Belum ada obrolan aktif',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                }

                                // Konversi ke list dan sort by waktu terbaru
                                final conversations = conversationMap.values.toList();
                                conversations.sort((a, b) {
                                  final aTime = a['created_at']?.toString() ?? '';
                                  final bTime = b['created_at']?.toString() ?? '';
                                  return bTime.compareTo(aTime);
                                });

                                // Filter berdasarkan search query menggunakan partner_id
                                // (nama akan di-fetch secara async di ChatItem)

                                return FutureBuilder<List<_ConversationData>>(
                                  future: _buildConversationList(conversations, myId, supabase),
                                  builder: (context, futureSnapshot) {
                                    if (!futureSnapshot.hasData) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    var convList = futureSnapshot.data!;

                                    // Filter search
                                    if (_searchQuery.isNotEmpty) {
                                      convList = convList.where((c) {
                                        return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                            c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
                                      }).toList();
                                    }

                                    if (convList.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'Tidak ada percakapan yang cocok',
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 16),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: convList.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(height: 1, indent: 80),
                                      itemBuilder: (context, index) {
                                        final conv = convList[index];
                                        return ChatItem(
                                          name: conv.name,
                                          receiverId: conv.partnerId,
                                          lastMessage: conv.lastMessage,
                                          time: formatChatTime(conv.time),
                                          unread: 0,
                                        );
                                      },
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

  // Ambil nama partner dari tabel profiles/users
  Future<List<_ConversationData>> _buildConversationList(
    List<Map<String, dynamic>> conversations,
    String myId,
    SupabaseClient supabase,
  ) async {
    final List<_ConversationData> result = [];

    for (final msg in conversations) {
      final senderId = msg['sender_id']?.toString() ?? '';
      final receiverId = msg['receiver_id']?.toString() ?? '';
      final partnerId = senderId == myId ? receiverId : senderId;

      if (partnerId.isEmpty) continue;

      String partnerName = 'Unknown';
      try {
        final profileData = await supabase
            .from('users') 
            .select('name') 
            .eq('id', partnerId)
            .maybeSingle();

        if (profileData != null) {
          partnerName = profileData['full_name']?.toString() ??
              profileData['name']?.toString() ??
              'Unknown';
        }
      } catch (e) {
        debugPrint('Gagal ambil profil partner: $e');
      }

      // Tentukan last message preview
      String lastMessage = '';
      final msgType = msg['message_type']?.toString() ?? 'text';
      if (msgType == 'image') {
        lastMessage = '🖼️ Gambar';
      } else if (msgType == 'file') {
        lastMessage = '📁 File';
      } else if (msgType == 'offer') {
        lastMessage = '💼 Penawaran Khusus';
      } else {
        lastMessage = msg['message_content']?.toString() ?? '';
      }

      result.add(_ConversationData(
        partnerId: partnerId,
        name: partnerName,
        lastMessage: lastMessage,
        time: msg['created_at']?.toString() ?? '',
      ));
    }

    return result;
  }
}

// Data class helper
class _ConversationData {
  final String partnerId;
  final String name;
  final String lastMessage;
  final String time;

  _ConversationData({
    required this.partnerId,
    required this.name,
    required this.lastMessage,
    required this.time,
  });
}

class ChatItem extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final String receiverId;

  const ChatItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    required this.receiverId,
  });

  String getInitials(String name) {
    List<String> names = name.trim().split(" ");
    String initials = "";
    if (names.length >= 2) {
      initials = names[0][0] + names[1][0];
    } else if (names.isNotEmpty && names[0].isNotEmpty) {
      initials = names[0][0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatPage(name: name, receiverId: receiverId)),
        );
      },
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF3B5998),
            child: Text(
              getInitials(name),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
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
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: unread > 0
                  ? const Color(0xFFE68C3A)
                  : Colors.grey,
              fontWeight:
                  unread > 0 ? FontWeight.bold : FontWeight.normal,
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
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE68C3A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}