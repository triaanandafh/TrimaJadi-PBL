import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final String name;

  const ChatPage({super.key, required this.name});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  Future<void> pickDocument() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    PlatformFile file = result.files.first;

    setState(() {
      messages.add({
        "type": "file",
        "name": file.name,
        "path": file.path,
        "isMe": true,
      });
    });

    // TODO: kirim ke chat bubble
  } else {
    print("User cancel pilih file");
  }
}

  final ImagePicker _picker = ImagePicker();

Future<void> pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    setState(() {
      messages.add({
        "type": "image",
        "path": image.path,
        "isMe": true,
      });
    });

    // TODO: tampilkan di chat bubble
  }
}

  List<Map<String, dynamic>> messages = [
    {"type": "text", "text": "Halo 👋", "isMe": false},
  ];
  
  String get name => widget.name;
  Widget build(BuildContext context) {
    bool isTalent = UserData.role == "Talent";

    return Scaffold(
      backgroundColor: Colors.white,

      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[700]),
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),

      // --- BODY ---
      body: Column(
        children: [

          // CHAT LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
              dateLabel("Kemarin"),
                chatBubble("Halo kak 👋", false),
                chatBubble("Halo! Ada yang bisa dibantu?", true),
                chatBubble("Saya mau tanya soal jasa desain", false),
                chatBubble("Boleh, silakan 🙌", true),
              ],
            ),
          ),

          // INPUT CHAT
          chatInput(context),
        ],
      ),
    );
  }

  // --- CHAT BUBBLE ---
  Widget chatBubble(String text, bool isMe) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
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
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // --- INPUT FIELD ---
  Widget chatInput(BuildContext context) {
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
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (context) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // --- DOKUMEN ---
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(Icons.insert_drive_file, color: Colors.blue[400]),
                        ),
                        title: const Text("Dokumen"),
                        onTap: () {
                          Navigator.pop(context);
                          pickDocument();
                        },
                      ),

                      // --- GAMBAR ---
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.image, color: Colors.purple[400]),
                        ),
                        title: const Text("Gambar"),
                        onTap: () {
                          Navigator.pop(context);
                          pickImage();
                        
                          setState(() {
                          messages.add({
                            "type": "image",
                            "url": "assets/images/poster.jpg",
                            "isMe": true,
                            });
                          });
                        },
                      ),

                      // --- KARTU PENAWARAN ---
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(Icons.local_offer, color: Colors.orange[400]),
                        ),
                        title: const Text("Kartu Penawaran"),
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) {
                            return const KartuPenawaran();
                          },
                        );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: const Icon(Icons.add, size: 28),
        ),
        const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Ketik pesan...",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE68C3A),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class KartuPenawaran extends StatelessWidget {
  const KartuPenawaran({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // TITLE
          const Text(
            "Buat Penawaran",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // JUDUL
          TextField(
            decoration: InputDecoration(
              labelText: "Judul Layanan",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // HARGA
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Harga",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // DESKRIPSI
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Deskripsi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // BUTTON
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
                Navigator.pop(context);
                print("Penawaran dikirim");
              },
              child: const Text("Kirim Penawaran", style: TextStyle(color: Colors.white)),
            ),
          ),

        ],
      ),
    );
  }
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