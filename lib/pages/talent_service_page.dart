import 'package:flutter/material.dart';
import 'package:trimajadi/pages/add_service_page.dart';
// import 'tambah_layanan_page.dart'; --- IGNORE ---

class LayananPage extends StatelessWidget {
  const LayananPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Layanan Saya", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contoh item layanan
          _serviceItem(
            context,
            title: "Desain Logo Minimalis",
            category: "Desain Grafis",
            price: "Rp 150.000",
          ),
          _serviceItem(
            context,
            title: "Slicing UI Flutter",
            category: "Pemrograman",
            price: "Rp 500.000",
          ),
        ],
      ),
      // TOMBOL TAMBAH LAYANAN
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE68C3A), // Orange sesuai tema navbarmu
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddServicePage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _serviceItem(BuildContext context, {required String title, required String category, required String price}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image, color: Color(0xFF1A43BF)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(price, style: const TextStyle(color: Color(0xFFE68C3A), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Tombol untuk Edit
          IconButton(
            onPressed: () {
              // Navigasi ke halaman edit (biasanya membawa data)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddServicePage()),
              );
            },
            icon: const Icon(Icons.edit_note, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}