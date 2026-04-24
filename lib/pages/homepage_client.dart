import 'package:flutter/material.dart';
import '../widgets/category_item.dart';
import '../widgets/service_item.dart';
import '../widgets/box.dart';
import '../models/user_model.dart';
import '../pages/searching_page.dart';

class HomepageClient extends StatelessWidget {
final VoidCallback onTapSearch;
const HomepageClient({super.key, required this.onTapSearch});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A43BF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white24,
                                      child: Icon(Icons.person, color: Colors.white, size: 20),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Hello, Tria👋',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications, color: Colors.orange, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -25,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                      child: TextField(
                        readOnly: true,
                        onTap: onTapSearch,
                        decoration: InputDecoration(
                          hintText: 'Search for services...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 45),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(context, "Kategori Layanan"),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CategoryItem(label: 'Desain', icon: Icons.palette, bgColor: Colors.orange[50]!, iconColor: Colors.orange[700]!),
                      CategoryItem(label: 'Web & Prog', icon: Icons.code, bgColor: Colors.blue[50]!, iconColor: Colors.blue[700]!),
                      CategoryItem(label: 'Edukasi', icon: Icons.school, bgColor: Colors.green[50]!, iconColor: Colors.green[700]!),
                      CategoryItem(label: 'Visual Audio', icon: Icons.music_note, bgColor: Colors.purple[50]!, iconColor: Colors.purple[700]!),
                      CategoryItem(label: 'Penulisan', icon: Icons.edit, bgColor: Colors.green[50]!, iconColor: Colors.green[700]!),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Promo Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 17, 155, 224),
                        image: DecorationImage(
                          image: AssetImage('assets/images/promo.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Text(
                              'Creative solutions for your home',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Dapatkan diskon hingga 30% untuk layanan tertentu.',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  sectionTitle(context, "Layanan Populer"),
                  const SizedBox(height: 15),

                  // Horizontal Service Cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ServiceCard("Desain Logo", "assets/images/desain_logo.png"),
                        ServiceCard("Desain Logo Profesional", "assets/images/logo_profesional.png"),
                        ServiceCard("Desain Web", "assets/images/desain_web.png"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget sectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: onTapSearch,
          child:
        Text(
          "Lihat Semua",
          style: TextStyle(fontSize: 13, color: Colors.blueGrey),
        ),
        ),
      ],
    );
  }

  Widget CategoryItem({required String label, required IconData icon, required Color bgColor, required Color iconColor}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.blueGrey[800]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Perbaikan Utama pada Fungsi ServiceCard
Widget ServiceCard(String title, String imgPath) {
  return Container(
    width: 155,
    margin: const EdgeInsets.only(right: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menampilkan Gambar dari Assets
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              imgPath,
              fit: BoxFit.cover, // Gambar akan memenuhi area tanpa merusak aspek rasio
              errorBuilder: (context, error, stackTrace) {
                // Widget cadangan jika file gambar tidak ditemukan
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}