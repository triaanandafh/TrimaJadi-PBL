import 'package:flutter/material.dart';

class CariLayananPage
    extends
        StatelessWidget {
  const CariLayananPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              // Header: Judul & Notifikasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Cari Layanan",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      size: 30,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              // Search Bar & Filter Icon
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search",
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.all(
                      10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              // List Kategori Layanan
              _buildCategoryCard(
                context,
                title: "Desain",
                subtitle: "Logo, seni, dan ilustrasi",
                icon: Icons.palette,
                bgColor: const Color(
                  0xFFE3F2FD,
                ),
                iconColor: Colors.blue.shade700,
              ),
              _buildCategoryCard(
                context,
                title: "Web & Pemrograman",
                subtitle: "Pengembangan Website",
                icon: Icons.code,
                bgColor: const Color(
                  0xFFFFF3E0,
                ),
                iconColor: const Color(
                  0xFFE68C3A,
                ), // Orange kita
              ),
              _buildCategoryCard(
                context,
                title: "Edukasi",
                subtitle: "Bimbingan belajar, tugas, mentoring",
                icon: Icons.school,
                bgColor: const Color(
                  0xFFF3E5F5,
                ),
                iconColor: Colors.purple.shade700,
              ),
              _buildCategoryCard(
                context,
                title: "Visual dan Audio",
                subtitle: "Voice Over, edit video, podcast.",
                icon: Icons.music_note,
                bgColor: const Color(
                  0xFFE0F2F1,
                ),
                iconColor: Colors.teal.shade700,
              ),
              _buildCategoryCard(
                context,
                title: "Penulisan & Penerjemahan",
                subtitle: "Olah kata konten, artikel, esai",
                icon: Icons.translate,
                bgColor: const Color(
                  0xFFE8F5E9,
                ),
                iconColor: Colors.green.shade700,
              ),
              const SizedBox(
                height: 100,
              ), 
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Kartu Kategori
  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.03,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 40,
            color: iconColor,
          ),
          const SizedBox(
            width: 20,
          ),
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
                const SizedBox(
                  height: 4,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
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
