import 'package:flutter/material.dart';

class AddServicePage extends StatelessWidget {
  const AddServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tambah Layanan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- JUDUL ---
            _sectionLabel("Judul Layanan"),
            _customTextField(hint: "Contoh: Desain Logo Minimalis"),

            const SizedBox(height: 20),

            // --- DESKRIPSI ---
            _sectionLabel("Deskripsi"),
            _customTextField(hint: "Jelaskan detail layananmu...", maxLines: 4),

            const SizedBox(height: 20),

            // --- HARGA PAKET (Basic, Standard, Premium) ---
            _sectionLabel("Harga Paket"),
            const SizedBox(height: 10),
            _buildPriceTier("Basic", "Paket standar hemat"),
            _buildPriceTier("Standard", "Paket paling populer"),
            _buildPriceTier("Premium", "Layanan eksklusif & lengkap"),

            const SizedBox(height: 20),

            // --- UPLOAD GAMBAR ---
            _sectionLabel("Upload Gambar Portfolio"),
            const SizedBox(height: 10),
            _buildImageUpload(),

            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A43BF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Simpan Layanan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _customTextField({required String hint, int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[100]!),
        ),
      ),
    );
  }

  Widget _buildPriceTier(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.workspace_premium, color: title == "Basic" ? Colors.blue : (title == "Standard" ? Colors.orange : Colors.purple)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _customTextField(hint: "Masukkan harga paket $title (Rp)"),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid), // Harusnya dashed, butuh package tambahan
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text("Klik untuk upload", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}