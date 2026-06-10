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

  // Hapus satu percakapan (semua pesan antara myId dan partnerId)
  Future<void> _deleteConversation(
      BuildContext context, String myId, String partnerId) async {
    final supabase = Supabase.instance.client;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Percakapan'),
        content:
            const Text('Yakin ingin menghapus semua pesan di percakapan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Hapus semua pesan antara dua user ini (kedua arah)
      await supabase.from('chat_messages').delete().or(
          'and(sender_id.eq.$myId,receiver_id.eq.$partnerId),and(sender_id.eq.$partnerId,receiver_id.eq.$myId)');

      // Hapus juga dari tabel chats (kedua sisi)
      await supabase.from('chats').delete().or(
          'and(user_id.eq.$myId,partner_id.eq.$partnerId),and(user_id.eq.$partnerId,partner_id.eq.$myId)');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Percakapan dihapus')),
        );
      }
    } catch (e) {
      debugPrint('Gagal hapus percakapan: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  // Hapus semua percakapan milik user ini
  Future<void> _deleteAllConversations(
      BuildContext context, String myId) async {
    final supabase = Supabase.instance.client;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Percakapan'),
        content:
            const Text('Yakin ingin menghapus semua riwayat pesan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Semua',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('chat_messages')
          .delete()
          .or('sender_id.eq.$myId,receiver_id.eq.$myId');

      await supabase
          .from('chats')
          .delete()
          .or('user_id.eq.$myId,partner_id.eq.$myId');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua percakapan dihapus')),
        );
      }
    } catch (e) {
      debugPrint('Gagal hapus semua: $e');
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 25, vertical: 15),
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

                      // ── TITIK TIGA dengan opsi Hapus Semua ──
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withOpacity(0.2),
                        ),
                        onSelected: (value) {
                          if (value == 'delete_all') {
                            _deleteAllConversations(context, myId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'delete_all',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep_outlined,
                                    color: Colors.red, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Hapus Semua Pesan',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── JUMLAH PERCAKAPAN AKTIF (fix: pakai sorted pair key) ──
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
                    // Hitung unique conversation dengan sorted-pair key
                    final Set<String> conversationKeys = {};
                    for (final msg in snapshot.data ?? []) {
                      final a = msg['sender_id']?.toString() ?? '';
                      final b = msg['receiver_id']?.toString() ?? '';
                      final List<String> pair = [a, b]..sort();
                      conversationKeys.add(pair.join('_'));
                    }
                    return Padding(
                      padding:
                          const EdgeInsets.only(left: 25, bottom: 20),
                      child: Text(
                        "${conversationKeys.length} percakapan aktif",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20),
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
                        // SEARCH BAR
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                                  color: Colors.grey.shade500,
                                  fontSize: 14),
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
                                  const EdgeInsets.symmetric(
                                      vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        // LIST PERCAKAPAN
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            child: StreamBuilder<
                                List<Map<String, dynamic>>>(
                              stream: supabase
                                  .from('chat_messages')
                                  .stream(primaryKey: ['id'])
                                  .order('created_at',
                                      ascending: false),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child:
                                          CircularProgressIndicator());
                                }

                                final allMessages =
                                    snapshot.data ?? [];

                                if (allMessages.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Belum ada obrolan aktif',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16),
                                    ),
                                  );
                                }

                                // Ambil pesan terbaru per unique conversation
                                final Map<String,
                                        Map<String, dynamic>>
                                    conversationMap = {};

                                for (final msg in allMessages) {
                                  final senderId =
                                      msg['sender_id']?.toString() ??
                                          '';
                                  final receiverId =
                                      msg['receiver_id']
                                              ?.toString() ??
                                          '';

                                  if (senderId != myId &&
                                      receiverId != myId) continue;

                                  final List<String> pair = [
                                    senderId,
                                    receiverId
                                  ]..sort();
                                  final String key = pair.join('_');

                                  if (!conversationMap
                                      .containsKey(key)) {
                                    conversationMap[key] = msg;
                                  }
                                }

                                if (conversationMap.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Belum ada obrolan aktif',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16),
                                    ),
                                  );
                                }

                                final conversations =
                                    conversationMap.values.toList();
                                conversations.sort((a, b) {
                                  final aTime =
                                      a['created_at']?.toString() ??
                                          '';
                                  final bTime =
                                      b['created_at']?.toString() ??
                                          '';
                                  return bTime.compareTo(aTime);
                                });

                                return FutureBuilder<
                                    List<_ConversationData>>(
                                  future: _buildConversationList(
                                      conversations, myId, supabase),
                                  builder: (context, futureSnapshot) {
                                    if (!futureSnapshot.hasData) {
                                      return const Center(
                                          child:
                                              CircularProgressIndicator());
                                    }

                                    var convList =
                                        futureSnapshot.data!;

                                    if (_searchQuery.isNotEmpty) {
                                      convList = convList
                                          .where((c) {
                                        return c.name
                                                .toLowerCase()
                                                .contains(_searchQuery
                                                    .toLowerCase()) ||
                                            c.lastMessage
                                                .toLowerCase()
                                                .contains(_searchQuery
                                                    .toLowerCase());
                                      }).toList();
                                    }

                                    if (convList.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'Tidak ada percakapan yang cocok',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16),
                                        ),
                                      );
                                    }

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: convList.length,
                                      separatorBuilder:
                                          (context, index) =>
                                              const Divider(
                                                  height: 1,
                                                  indent: 80),
                                      itemBuilder: (context, index) {
                                        final conv = convList[index];
                                        return Dismissible(
                                          key: Key(conv.partnerId),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment:
                                                Alignment.centerRight,
                                            padding:
                                                const EdgeInsets.only(
                                                    right: 20),
                                            color: Colors.red,
                                            child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                                size: 28),
                                          ),
                                          confirmDismiss: (direction) async {
                                            await _deleteConversation(
                                                context,
                                                myId,
                                                conv.partnerId);
                                            return false; // stream otomatis update
                                          },
                                          child: ChatItem(
                                            name: conv.name,
                                            receiverId: conv.partnerId,
                                            lastMessage: conv.lastMessage,
                                            time: formatChatTime(
                                                conv.time),
                                            unread: 0,
                                            onDelete: () =>
                                                _deleteConversation(
                                                    context,
                                                    myId,
                                                    conv.partnerId),
                                          ),
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
  final VoidCallback? onDelete;

  const ChatItem({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    required this.receiverId,
    this.onDelete,
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
              builder: (_) =>
                  ChatPage(name: name, receiverId: receiverId)),
        );
      },
      onLongPress: () {
        // Long press: tampilkan opsi hapus untuk percakapan ini
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  title: const Text('Hapus Percakapan',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete?.call();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
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