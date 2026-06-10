import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'detail_order_page.dart';
import 'talent_profile_preview_page.dart';
import 'dart:io';
import 'chat_list_page.dart';

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

  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    final otherController = TextEditingController();
    final reasons = [
      'Penipuan / Scam',
      'Konten tidak pantas',
      'Spam',
      'Pelecehan / Ancaman',
      'Lainnya',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Laporkan Pengguna',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih alasan laporan:',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                ...reasons.map((reason) => RadioListTile<String>(
                      value: reason,
                      groupValue: selectedReason,
                      title: Text(reason, style: const TextStyle(fontSize: 14)),
                      activeColor: const Color(0xFFE68C3A),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (val) => setDialogState(() => selectedReason = val),
                    )),
                // TextField muncul hanya saat pilih "Lainnya"
                if (selectedReason == 'Lainnya') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: otherController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan alasan kamu...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE68C3A)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE68C3A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      // Jika "Lainnya" tapi field kosong, tidak bisa kirim
                      if (selectedReason == 'Lainnya' && otherController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Mohon tuliskan alasan kamu.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final finalReason = selectedReason == 'Lainnya'
                          ? 'Lainnya: ${otherController.text.trim()}'
                          : selectedReason!;

                      Navigator.pop(ctx);
                      try {
                        final myId = supabase.auth.currentUser?.id;
                        if (myId == null) return;

                        await supabase.from('reports').insert({
                          'reporter_id': myId,
                          'reported_id': widget.receiverId,
                          'reason': finalReason,
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Laporan berhasil dikirim. Terima kasih.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kamu sudah pernah melaporkan pengguna ini.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Kirim Laporan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

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
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TalentProfilePreviewPage(
                      talentId: widget.receiverId,
                      talentName: widget.name,
                    ),
                  ),
                );
              } else if (value == 'report') {
                _showReportDialog(context);
              }
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
                  bubbleWidget = _buildOfferCard(offerData,msg, isMe, isTalent);
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


Widget _buildOfferCard(Map<String, dynamic> offer, Map<String, dynamic> msg, bool isMe, bool isTalent) {
  // ✅ Handle int, double, dan string sekaligus
  final int priceVal = (num.tryParse(offer['price'].toString()) ?? 0).toInt();
  
  return Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 270),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE68C3A), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("KARTU PENAWARAN JASA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE68C3A))),
          const SizedBox(height: 6),
          Text(offer['title'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(_formatRupiah(priceVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E))),
          const SizedBox(height: 6),
          Text(offer['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Divider(height: 16),
          if (!isMe && !isTalent) // Muncul hanya di sisi Client penerima
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE68C3A)),
                onPressed: () async {
                  try {
                    final String title = offer['title'] ?? 'Layanan Kustom';
                    final myId = Supabase.instance.client.auth.currentUser?.id;

                    if (myId == null) return;

                    final talentId = offer['sender_id']?.toString();
               
                    if (talentId == null) return;

                    final orderResult = await Supabase.instance.client.from('orders').insert({
                      'client_id'     : myId,
                      'talent_id'     : talentId,
                      'service_name'  : '$title - Paket Kustom',
                      'package_type'  : 'custom',
                      'total_price'   : priceVal,
                      'payment_status': 'unpaid',
                      'work_status'   : 'pending',
                      'order_date'    : DateTime.now().toIso8601String().split('T')[0],
                      'description'   : offer['description'] ?? '',
                      'duration'      : 7, 
                    }).select().single();
                    debugPrint('Order berhasil: $orderResult');

                    final newOrderId = orderResult['id'].toString();

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailOrderPage(
                            orderId : newOrderId,
                            isTalent: false,
                            status  : 'pending',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Gagal membuat order dari offer: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal membuat order: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Terima & Bayar", style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    ),
  );
}
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