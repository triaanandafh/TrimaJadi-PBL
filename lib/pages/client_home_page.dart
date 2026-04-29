import 'package:flutter/material.dart';

class HomepageClient extends StatelessWidget {
  final VoidCallback onTapSearch;

  const HomepageClient({super.key, required this.onTapSearch});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF), 
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header & Search Bar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 135,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A43BF), 
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 25, right: 25, top: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white, size: 24),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Halo, Tria!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none, color: Color(0xFFE68C3A), size: 26),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Search Bar Box
                Positioned(
                  bottom: -25,
                  left: 25,
                  right: 25,
                  child: GestureDetector(
                    onTap: onTapSearch, 
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 10),
                            Text("Cari layanan...", style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Bagian Kategori
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Kategori Populer"),
                  const SizedBox(height: 20),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryItem('Desain', Icons.palette, const Color(0xFFE3F2FD), Colors.blue.shade700),
                        _buildCategoryItem('Web & Pemrograman', Icons.code, const Color(0xFFFFF3E0), const Color(0xFFE68C3A)),
                        _buildCategoryItem('Edukasi', Icons.school, const Color(0xFFF3E5F5), Colors.purple.shade700),
                        _buildCategoryItem('Visual & Audio', Icons.music_note, const Color(0xFFE0F2F1), Colors.teal.shade700),
                        _buildCategoryItem('Penulisan', Icons.translate, const Color(0xFFE8F5E9), Colors.green.shade700),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 35),
                  
                  // Promo Card (Hanya Gambar)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 35),
                  _buildSectionTitle("Layanan Populer"),
                  const SizedBox(height: 15),

                  // List Layanan Populer
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildServiceCard("Desain Poster", "assets/images/desain_logo.png"),
                        _buildServiceCard("Edukasi", "assets/images/logo_profesional.png"),
                        _buildServiceCard("Desain Web", "assets/images/desain_web.png"),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF213E60)),
        ),
        const Text(
          "Lihat Semua",
          style: TextStyle(fontSize: 13, color: Color(0xFF94B6EF), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Widget Category dengan label Penulisan & Wrap Text
  Widget _buildCategoryItem(String label, IconData icon, Color bgColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 75, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
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
            const SizedBox(height: 10),
            SizedBox(
              height: 35, 
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                maxLines: 2,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, String imgPath) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              image: DecorationImage(
                image: AssetImage(imgPath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}