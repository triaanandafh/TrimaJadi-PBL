import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'chat_list_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'detail_order_page.dart';

class ChatPage extends StatefulWidget {
  final String name;
  final String receiverId;

  const ChatPage({super.key, required this.name, required this.receiverId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "00:00";
    }
  }

  String _getDateLabel(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return "Hari ini";
  try {
    DateTime chatDate = DateTime.parse(dateStr).toLocal();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime targetDay = DateTime(chatDate.year, chatDate.month, chatDate.day);

    if (targetDay == today) {
      return "Hari ini";
    } else if (targetDay == yesterday) {
      return "Kemarin";
    } else {
      return "${chatDate.day}/${chatDate.month}/${chatDate.year}";
    }
  } catch (_) {
    return "Hari ini";
  }
}

String _formatRupiah(dynamic value) {
    if (value == null) return 'Rp 0';
    final num amount = value is num ? value : num.tryParse(value.toString()) ?? 0;
    final str    = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

Future<void> openFile(String url) async {
  final uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,);
  }
}

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty) return;
    _controller.clear(); // Bersihkan field text input secara instan

    try {
      final myId = supabase.auth.currentUser?.id;
      debugPrint("===== SEND MESSAGE =====");
debugPrint("myId         : $myId");
debugPrint("receiverId   : ${widget.receiverId}");
debugPrint("receiverName : ${widget.name}");
debugPrint("message      : $text");
      if (myId == null) return;

      // 1. Insert ke tabel chat_messages (Menggunakan nama kolom 'message_conten')
      final result = await supabase.from('chat_messages').insert({
        'sender_id': myId,
        'receiver_id': widget.receiverId,
        'message_type': 'text',
        'message_content': text, // Menyesuaikan nama kolom database kamu
      })
      .select();
      
      
      // 2. Update status ke tabel chats utama agar Chat List terperbarui
      await supabase.from('chats').upsert({
        'user_id': myId,
        'partner_id': widget.receiverId,
        'name': widget.name,
        'last_message': text,
        'time': DateTime.now().toIso8601String(),
        'unread': 0,
      }, onConflict: 'user_id, partner_id');
      print("INSERT BERHASIL");  //DEBUG
    } catch (e) {
      debugPrint('Gagal mengirim pesan: $e');
    }
  }

  Future<void> pickDocument() async {
  FilePickerResult? result = await FilePicker.pickFiles(withData: true,);
  if (result == null) return;

  final PlatformFile file = result.files.first;
  if (file.bytes == null) return;
      try {
        final myId = supabase.auth.currentUser?.id;
        if (myId == null) return;

        // 1. Upload ke Supabase Storage
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

        await supabase.storage
        .from('chat-files')
        .uploadBinary(
          'documents/$fileName',
          file.bytes!,
        );

    // 2. Ambil public URL
        final publicUrl = supabase.storage
        .from('chat-files')
        .getPublicUrl('documents/$fileName');

        // Simpan info dokumen ke tabel chat_messages
        await supabase.from('chat_messages').insert({
          'sender_id': myId,
          'receiver_id': widget.receiverId,
          'message_type': 'file',
          'message_content': jsonEncode({   // ← gabungkan nama + url
          'name': file.name,
          'url' : publicUrl,
        }), // Nama file disimpan di sini
          // 'file_path': publicUrl,      // Path lokal file
        });

        // Perbarui pratinjau di list chat utama
        await supabase.from('chats').upsert({
          'user_id': myId,
          'partner_id': widget.receiverId,
          'name': widget.name,
          'last_message': '📁 ${file.name}',
          'time': DateTime.now().toIso8601String(),
          'unread': 0,
        }, onConflict: 'user_id, partner_id');

      } catch (e) {
        debugPrint("Gagal mengunggah dokumen: $e");
      }
    
  }

  final ImagePicker _picker = ImagePicker();

Future<void> pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    try{
      final myId = supabase.auth.currentUser?.id;
      if (myId == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final fileBytes = await image.readAsBytes();

      await supabase.storage
        .from('chat-files')
        .uploadBinary(
          'images/$fileName',
          fileBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // 2. Ambil public URL
    final publicUrl = supabase.storage
        .from('chat-files')
        .getPublicUrl('images/$fileName');
        
      // Simpan info gambar ke tabel chat_messages
      // await supabase.from('chat_messages').insert({
      //   'sender_id': myId,
      //   'partner_id': widget.receiverId,
      //   // 'chat_partner_name': widget.name,
      //   'message_type': 'image',
      //   'message_content': image.name, // Nama file disimpan di sini
      //   'file_path': image.path,      // Path lokal file
      // });

      await supabase.from('chat_messages').insert({
      'sender_id'      : myId,
      'receiver_id'    : widget.receiverId,  // ✅ fix
      'message_type'   : 'image',
      'message_content': publicUrl,          // ✅ simpan URL bukan path lokal
    });
      // Perbarui pratinjau di list chat utama
      // await supabase.from('chats').upsert({
      //   'user_id': myId,
      //   'receiver_id': widget.receiverId,
      //   'name': widget.name,
      //   'last_message': '🖼️ ${image.name}',
      //   'time': DateTime.now().toIso8601String(),
      //   'unread': 0,
      // }, onConflict: 'user_id, partner_id');

       await supabase.from('chats').upsert({
      'user_id'     : myId,
      'partner_id'  : widget.receiverId,
      'name'        : widget.name,
      'last_message': '🖼️ Gambar',
      'time'        : DateTime.now().toIso8601String(),
      'unread'      : 0,
    }, onConflict: 'user_id, partner_id');


    } catch (e) {
      debugPrint("Gagal mengunggah gambar: $e");
    }
  }
}

Future<void> _sendCustomOffer(String title, int price, String description) async {
    try {
      final myId = supabase.auth.currentUser?.id;
      if (myId == null) return;

      final offerJson = jsonEncode({
        'title': title,
        'price': price,
        'description': description,
        'status': 'pending',
        'sender_id'  : myId,          
        'receiver_id': widget.receiverId
      });

      await supabase.from('chat_messages').insert({
        'sender_id': myId,
        'receiver_id': widget.receiverId,
        // 'chat_partner_name': widget.name,
        'message_type': 'offer',
        'message_content': offerJson,
      });

      await supabase.from('chats').upsert({
        'user_id': myId,
        'partner_id': widget.receiverId,
        'name': widget.name,
        'last_message': '💼 Menawarkan Penawaran Khusus',
        'time': DateTime.now().toIso8601String(),
        'unread': 0,
      }, onConflict: 'user_id, partner_id');

    } catch (e) {
      debugPrint('Gagal mengirim kartu penawaran: $e');
    }
  }
  
  String get name => widget.name;

  @override
  Widget build(BuildContext context) {
    bool isTalent = UserData.role == "Talent";
    final myId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200, // Warna garis abu-abu soft khas mockup
            width: 1.0, // Ketebalan garis pembatas
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF3B5998),
            child: Text(
              getInitials(name),
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 14,
                
              ),
            ),
          ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
              name,
              style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              "Online",
              style: TextStyle(color: Colors.grey.shade500, 
                    fontSize: 11, 
                    fontWeight: FontWeight.normal),
            )
              ],
            )
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            color: Colors.white,
            onSelected: (value) {
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Text('Lihat Profil'),
                ),
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Text('Laporkan Pengguna'),
                ),
              ];
            },
          ),
        ],
      ),

      // --- BODY ---
      body: Column(
        children: [

          // CHAT LIST
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Ganti StreamBuilder stream-nya dengan ini
              stream: supabase
              .from('chat_messages')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: true)
              .map((data) => data.where((msg) =>
                  (msg['sender_id'] == myId && msg['receiver_id'] == widget.receiverId) ||
                  (msg['sender_id'] == widget.receiverId && msg['receiver_id'] == myId)
              ).toList()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messagesList = snapshot.data ?? [];

                if (messagesList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Belum ada pesan. Mulai percakapan dengan mengirim pesan atau file.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.4),
                      ),
                    ),
                  );
                }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messagesList.length,
              itemBuilder: (context, index) {
                final msg = messagesList[index];
                final createdAt = msg['created_at']?.toString() ?? DateTime.now().toIso8601String();
                final chatTime = _formatTime(createdAt);
                final isMe = msg['sender_id'] == myId;
                
                bool showDateLabel = false;
                      if (index == 0) {
                        showDateLabel = true; // Pesan pertama selalu memunculkan tanggal
                      } else {
                        final prevMsg = messagesList[index - 1];
                        final currentLabel = _getDateLabel(createdAt);
                        final prevLabel = _getDateLabel(prevMsg['created_at']?.toString() ?? DateTime.now().toIso8601String());
                        if (currentLabel != prevLabel) {
                          showDateLabel = true; // Munculkan jika harinya berganti
                        }
                      }

                      // Widget chat bubble utama yang akan di-render
                Widget bubbleWidget;
                if (msg['message_type'] == "image") { 
                  bubbleWidget =  Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFE68C3A) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.network(
                      msg['message_content'],
                      fit: BoxFit.cover,
                    ),
                    ),
                  );
                }else if (msg['message_type'] == "file") {
                  String fileName = 'File';
                  String fileUrl  = '';

                  try {
                    // Data baru: format JSON {"name": "...", "url": "..."}
                    final fileData = jsonDecode(msg['message_content'] ?? '{}');
                    fileName = fileData['name'] ?? 'File';
                    fileUrl  = fileData['url']  ?? '';
                  } catch (_) {
                    // Data lama: plain text berisi nama file saja
                    fileName = msg['message_content'] ?? 'File';
                    fileUrl  = msg['file_path']       ?? ''; // fallback ke file_path jika ada
                  }

                  bubbleWidget = GestureDetector(
                  onTap: () => openFile(fileUrl),
                  child: chatBubble(
                    "📄 $fileName",
                    isMe,
                    timeStr: chatTime,
                  ),
                );
                } else if (msg['message_type'] == "offer") {
                  final offerData = jsonDecode(msg['message_content'] ?? '{}');
                  // bubbleWidget = _buildOfferCard(offerData,msg, isMe, isTalent);
                  bubbleWidget = OfferCard(
                    offer     : offerData,
                    isMe      : isMe,
                    isTalent  : isTalent,
                    myId      : myId,
                    receiverId: widget.receiverId,
                  );
                }
                else {
                  bubbleWidget = chatBubble(msg['message_content'], isMe, timeStr: chatTime);
                }

                if (showDateLabel) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            dateLabel(_getDateLabel(createdAt)), // Widget dateLabel bawaan tokomu
                            bubbleWidget,
                          ],
                        );
                      } else {
                        return bubbleWidget;
                      }
                    },
                  );
                },
              ),
          ),
          // INPUT CHAT
          chatInput(context),
        ],
      ),
    );
  }


// 


  // --- CHAT BUBBLE ---
  Widget chatBubble(String text, bool isMe, {String? timeStr}) {
    final displayTime = timeStr ?? "08:26";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE68C3A) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft:
                isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 15,
          runSpacing: 4,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
              ),
            Text(
              displayTime,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
        ),
          ],
        ),
      ),
    );
  }

  // --- INPUT FIELD ---
Widget chatInput(BuildContext context) {
  debugPrint('UserData.role = ${UserData.role}');
  final isTalent = UserData.role?.toLowerCase() == "talent";
  debugPrint('isTalent = $isTalent');
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        top: BorderSide(color: Colors.grey[200]!),
      ),
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              builder: (ctx) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 30, left: 16, right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- DOKUMEN ---
                          _buildSheetItem(
                            context: ctx,
                            icon: Icons.insert_drive_file_outlined,
                            label: "Dokumen",
                            onTap: () => pickDocument(),
                          ),

                          // --- GAMBAR ---
                          _buildSheetItem(
                            context: ctx,
                            icon: Icons.image_outlined,
                            label: "Gambar",
                            onTap: () => pickImage(),
                          ),

                          // --- KARTU PENAWARAN (hanya Talent) ---
                          if (isTalent)
                            _buildSheetItem(
                              context: ctx,
                              icon: Icons.local_offer_outlined,
                              label: "Kartu\nPenawaran",
                              autoClose: false, 
                              onTap: () {
                                debugPrint('=== KARTU PENAWARAN TAPPED ===');
                                debugPrint('isTalent: $isTalent');
                                Navigator.pop(ctx);
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (modalCtx) {
                                      final titleCtrl = TextEditingController();
                                      final priceCtrl = TextEditingController();
                                      final descCtrl  = TextEditingController();

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                          top: 20,
                                          bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Text(
                                              "Buat Penawaran",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            TextField(
                                              controller: titleCtrl,
                                              decoration: const InputDecoration(
                                                labelText: "Judul Layanan",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            TextField(
                                              controller: priceCtrl,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: "Harga",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            TextField(
                                              controller: descCtrl,
                                              maxLines: 3,
                                              decoration: const InputDecoration(
                                                labelText: "Deskripsi",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFE68C3A),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(modalCtx);
                                                  final inputPrice = int.tryParse(priceCtrl.text.trim()) ?? 0;
                                                  _sendCustomOffer(
                                                    titleCtrl.text.trim(),
                                                    inputPrice,
                                                    descCtrl.text.trim(),
                                                  );
                                                },
                                                child: const Text(
                                                  "Kirim Penawaran",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, size: 22, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _sendMessage(),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Ketik pesan...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              filled: true,
              fillColor: const Color(0xFFF4F6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _sendMessage(),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE68C3A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    ),
  );
}


Widget dateLabel(String text) {
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    ),
  );
}

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

// Fungsi Helper untuk merender tombol icon bulat + teks di bawahnya persis seperti mockup
  Widget _buildSheetItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool autoClose = true,

  }) {
    return GestureDetector(
      onTap: () {
        if (autoClose) Navigator.pop(context);  // ← hanya pop jika autoClose true
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA), // Warna abu-abu soft netral persis contoh gambar kiri
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1C2D5A), // Warna biru navy gelap bawaan ikon tokomu
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class OfferCard extends StatefulWidget {
  final Map<String, dynamic> offer;
  final bool isMe;
  final bool isTalent;
  final String myId;
  final String receiverId;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isMe,
    required this.isTalent,
    required this.myId,
    required this.receiverId,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  final supabase = Supabase.instance.client;
  String? _paymentStatus; // null = belum ada order, 'unpaid', 'paid', 'cancelled', dll
  String? _orderId;
  bool _isLoading = true;
  bool _isCreatingOrder = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
  }

  Future<void> _fetchOrderStatus() async {
    try {
      final talentId = widget.offer['sender_id']?.toString();
      final clientId = widget.offer['receiver_id']?.toString();
      final title    = widget.offer['title']?.toString() ?? '';

      if (talentId == null || clientId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final result = await supabase
          .from('orders')
          .select('id, payment_status, work_status')
          .eq('talent_id', talentId)
          .eq('client_id', clientId)
          .eq('service_name', '$title - Paket Kustom')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _paymentStatus = result?['payment_status']?.toString();
          _orderId       = result?['id']?.toString();
          _isLoading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return 'Rp 0';
    final num amount = value is num ? value : num.tryParse(value.toString()) ?? 0;
    final str    = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  // Badge status di bawah kartu
  Widget _buildStatusBadge() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(
          backgroundColor: Color(0xFFFFE0B2),
          color: Color(0xFFE68C3A),
        ),
      );
    }

    if (_paymentStatus == null) return const SizedBox(); // belum ada order

    String   label;
    Color    color;
    Color    bgColor;
    IconData icon;

    switch (_paymentStatus) {
      case 'unpaid':
        label   = 'Menunggu Pembayaran';
        color   = Colors.orange;
        bgColor = Colors.orange.shade50;
        icon    = Icons.hourglass_empty;
        break;
      case 'pending':
        label   = 'Pembayaran Diproses';
        color   = Colors.blue;
        bgColor = Colors.blue.shade50;
        icon    = Icons.pending_outlined;
        break;
      case 'paid':
        label   = 'Sudah Dibayar ✓';
        color   = Colors.green;
        bgColor = Colors.green.shade50;
        icon    = Icons.check_circle_outline;
        break;
      case 'cancelled':
        label   = 'Dibatalkan';
        color   = Colors.red;
        bgColor = Colors.red.shade50;
        icon    = Icons.cancel_outlined;
        break;
      case 'failed':
        label   = 'Pembayaran Gagal';
        color   = Colors.red;
        bgColor = Colors.red.shade50;
        icon    = Icons.error_outline;
        break;
      default:
        label   = _paymentStatus!;
        color   = Colors.grey;
        bgColor = Colors.grey.shade50;
        icon    = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color       : bgColor,
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize   : 11,
                color      : color,
                fontWeight : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildActionButton(int priceVal) {
    if (_isLoading) return const SizedBox();

    // Sudah dibayar — tampilkan tombol lihat detail order
    if (_paymentStatus == 'paid') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side       : const BorderSide(color: Color(0xFF1A237E)),
            shape      : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (_orderId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailOrderPage(
                    orderId : _orderId!,
                    isTalent: false,
                    status  : 'progress',
                  ),
                ),
              );
            }
          },
          icon : const Icon(Icons.receipt_long_outlined,
              size: 16, color: Color(0xFF1A237E)),
          label: const Text(
            'Lihat Detail Order',
            style: TextStyle(color: Color(0xFF1A237E), fontSize: 13),
          ),
        ),
      );
    }

    // Menunggu pembayaran — tampilkan tombol lanjutkan bayar
    if (_paymentStatus == 'unpaid' && !widget.isMe && !widget.isTalent) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (_orderId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailOrderPage(
                    orderId : _orderId!,
                    isTalent: false,
                    status  : 'pending',
                  ),
                ),
              );
            }
          },
          icon : const Icon(Icons.payment, size: 16, color: Colors.white),
          label: const Text(
            'Lanjutkan Pembayaran',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }

    // Belum ada order sama sekali — tampilkan tombol Terima & Bayar
    if (_paymentStatus == null && !widget.isMe && !widget.isTalent) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE68C3A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isCreatingOrder ? null : () => _handleTerimaAndBayar(priceVal),
          child: _isCreatingOrder
              ? const SizedBox(
                  height: 18,
                  width : 18,
                  child : CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Terima & Bayar',
                  style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return const SizedBox();
  }

  Future<void> _handleTerimaAndBayar(int priceVal) async {
    setState(() => _isCreatingOrder = true);
    try {
      final myId     = supabase.auth.currentUser?.id;
      if (myId == null) return;

      final talentId = widget.offer['sender_id']?.toString() ?? widget.receiverId;
      final title    = widget.offer['title'] ?? 'Layanan Kustom';
      final now      = DateTime.now();
      final deadline = now.add(const Duration(days: 7));

      final orderResult = await supabase.from('orders').insert({
        'client_id'     : myId,
        'talent_id'     : talentId,
        'service_name'  : '$title - Paket Kustom',
        'package_type'  : 'custom',
        'total_price'   : priceVal,
        'payment_status': 'unpaid',
        'work_status'   : 'pending',
        'order_date'    : now.toIso8601String().substring(0, 10),
        'deadline'      : deadline.toIso8601String().substring(0, 10),
        'description'   : widget.offer['description'] ?? '',
        'duration'      : 7,
        'revision_count': 0,
      }).select().single();

      final newOrderId = orderResult['id'].toString();

      // Update state lokal agar tombol langsung berubah
      setState(() {
        _paymentStatus = 'unpaid';
        _orderId       = newOrderId;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailOrderPage(
              orderId : newOrderId,
              isTalent: false,
              status  : 'pending',
            ),
          ),
        ).then((_) => _fetchOrderStatus()); // refresh setelah kembali
      }
    } catch (e) {
      debugPrint('Gagal membuat order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content         : Text('Gagal membuat order: $e'),
            backgroundColor : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int priceVal =
        (num.tryParse(widget.offer['price'].toString()) ?? 0).toInt();

    return Align(
      alignment:
          widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin     : const EdgeInsets.symmetric(vertical: 8),
        padding    : const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration : BoxDecoration(
          color        : Colors.white,
          borderRadius : BorderRadius.circular(16),
          border       : Border.all(color: const Color(0xFFE68C3A), width: 1.5),
          boxShadow    : [
            BoxShadow(
              color    : Colors.black.withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "KARTU PENAWARAN JASA",
              style: TextStyle(
                fontSize  : 10,
                fontWeight: FontWeight.bold,
                color     : Color(0xFFE68C3A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.offer['title'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              _formatRupiah(priceVal),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize  : 14,
                color     : Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.offer['description'] ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 16),

            // Status badge
            _buildStatusBadge(),

            // Tombol aksi
            if (!widget.isMe || _paymentStatus == 'paid') ...[
              const SizedBox(height: 8),
              _buildActionButton(priceVal),
            ],
          ],
        ),
      ),
    );
  }
}

