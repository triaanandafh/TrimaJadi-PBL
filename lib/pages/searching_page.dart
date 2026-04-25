import 'package:flutter/material.dart';

class SearchingClient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Cari Layanan",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Icon(Icons.notifications_none, color: Colors.black87, size: 28),
                ],
              ),
              
              const SizedBox(height: 20),

              // --- SEARCH BAR & FILTER ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Filter
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- LIST KATEGORI VERTIKAL ---
              searchCategoryCard(
                title: "Desain",
                subtitle: "Logo, seni, dan ilustrasi",
                icon: Icons.palette,
                cardColor: const Color(0xFFE8F0FF), // Soft Blue
                iconColor: const Color(0xFF1A43BF),
              ),
              searchCategoryCard(
                title: "Web & Pemrograman",
                subtitle: "Pengembangan Website",
                icon: Icons.code,
                cardColor: const Color(0xFFFFF2E8), // Soft Orange
                iconColor: Colors.orange[800]!,
              ),
              searchCategoryCard(
                title: "Edukasi",
                subtitle: "Bimbingan belajar, tugas, mentoring",
                icon: Icons.school,
                cardColor: const Color(0xFFF3E8FF), // Soft Purple
                iconColor: Colors.purple[700]!,
              ),
              searchCategoryCard(
                title: "Visual dan Audio",
                subtitle: "Voice Over, edit video, podcast.",
                icon: Icons.music_note,
                cardColor: const Color(0xFFE8FFF8), // Soft Teal
                iconColor: Colors.teal[700]!,
              ),
              searchCategoryCard(
                title: "Penulisan & Penerjemahan",
                subtitle: "Olah kata konten, artikel, esai",
                icon: Icons.translate,
                cardColor: const Color(0xFFE8FFE8), // Soft Green
                iconColor: Colors.green[700]!,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk Kartu Kategori di Halaman Search
  Widget searchCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        // Menambahkan sedikit bayangan agar halus
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon dengan background lingkaran putih transparan agar terlihat bersih
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(width: 16),
          // Teks Judul dan Subjudul
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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