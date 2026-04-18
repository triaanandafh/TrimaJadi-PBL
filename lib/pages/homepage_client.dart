import 'package:flutter/material.dart';
import '../widgets/category_item.dart';
import '../widgets/service_item.dart';
import '../widgets/box.dart';
import '../widgets/custom_bottom_navbar.dart';

class HomepageClient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavbar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: ListView(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Halo, Tria",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.notifications_none)
                ],
              ),

              SizedBox(height: 10),

              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 15),

              sectionTitle("Kategori Populer"),

              // FIX: pakai horizontal scroll
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CategoryItem(text: "Desain", imagePath: 'assets/images/desain.jpeg'),
                    CategoryItem(text: "Edukasi", imagePath: 'assets/images/edukasi.jpeg'),
                    CategoryItem(text: "Pemrograman", imagePath: 'assets/images/pemrograman.jpeg'),
                    CategoryItem(text: "Visual Audio", imagePath: 'assets/images/visual_audio.jpeg'),
                    CategoryItem(text: "Penulisan", imagePath: 'assets/images/penulisan.jpeg'),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Box(height: 120), // banner lebih tinggi sesuai gambar

              SizedBox(height: 15),

              sectionTitle("Layanan Populer"),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ServiceItem(
                      title: "Desain Logo",
                      imagePath: "assets/images/desain_logo.jpeg",
                    ),
                    ServiceItem(
                      title: "Web Development",
                      imagePath: "assets/images/web_development.jpeg",
                    ),
                    ServiceItem(
                      title: "Video Editing",
                      imagePath: "assets/images/video_editing.jpeg",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text("Lihat Semua", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}