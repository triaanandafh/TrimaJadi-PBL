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
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications, color: Colors.orange, size: 24)
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
                          offset: Offset(0, 5),
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
                        CategoryItem(icon: Icons.palette, label: 'Desain', bgColor: Colors.orange[50]!, iconColor: Colors.orange[700]!),
                        CategoryItem(icon: Icons.code, label: 'Web & Prog', bgColor: Colors.blue[50]!, iconColor: Colors.blue[700]!),
                        CategoryItem(icon: Icons.school, label: 'Edukasi', bgColor: Colors.green[50]!, iconColor: Colors.green[700]!),
                        CategoryItem(icon: Icons.music_note, label: 'Visual Audio', bgColor: Colors.purple[50]!, iconColor: Colors.purple[700]!),
                        CategoryItem(icon: Icons.edit, label: 'Penulisan', bgColor: Colors.green[50]!, iconColor: Colors.green[700]!),
                      ],
                    ),
                  const SizedBox(height: 30),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                        
                            SizedBox(height: 10),
                            Text('Dapatkan diskon hingga 30% untuk layanan tertentu.'),
                          ],
                        ),

                      )
                    ),
                  ),
                  const SizedBox(height: 30),
                  sectionTitle(context, "Layanan Populer"),
                  const SizedBox(height: 15),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ServiceCard("Desain Poster", "assets/images/Desain logo minimalis.webp"),
                        ServiceCard("Desain Poster", "assets/images/poster.jpg"),
                        ServiceCard("Desain Poster", "assets/images/poster.jpg"),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.blueGrey[800]), textAlign: TextAlign.center),
      ],
    );
  }

}


Widget ServiceCard(String title, String imgPath) {
    return Container(
      width: 155,
      margin: EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder Gambar
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Center(child: Icon(Icons.image, color: Colors.grey[400])),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              title, 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
