import 'package:flutter/material.dart';
import '../models/user_model.dart'; // Pastikan path ini sesuai dengan struktur foldermu
import 'homepage_client.dart';
import 'homepage_seller.dart';
import 'profile_page.dart';
import 'cari_layanan.dart'; // Import halaman yang baru dibuat tadi

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Cek role user
    bool isSeller = UserData.role == "Seller";

    // Daftar halaman yang akan ditampilkan berdasarkan index
    final List<Widget> pages = [
      isSeller ? const HomeSellerPage() : HomepageClient(), // Index 0: Beranda
      const Center(child: Text("Halaman Order")),                 // Index 1: Order
      
      // Index 2: Tombol Tengah (Search untuk Client / Kelola Jasa untuk Seller)
      isSeller 
          ? const Center(child: Text("Halaman Tambah/Kelola Jasa Seller")) 
          : const CariLayananPage(), 
      
      const Center(child: Text("Halaman Chat")),                  // Index 3: Chat
      const ProfilePage(),                                        // Index 4: Profil
    ];

    return Scaffold(
      // Menggunakan IndexedStack agar state halaman (seperti scroll) tidak hilang saat pindah tab
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      
      bottomNavigationBar: Container(
        height: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Navigasi Kiri
            _buildNavItem(Icons.home_outlined, Icons.home, "Beranda", 0),
            _buildNavItem(Icons.assignment_outlined, Icons.assignment, "Order", 1),
            
            // Tombol Tengah (Action Button)
            _buildCenterItem(isSeller), 
            
            // Navigasi Kanan
            _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, "Chat", 3),
            _buildNavItem(Icons.person_outline, Icons.person, "Profil", 4),
          ],
        ),
      ),
    );
  }

  // Widget untuk item navigasi standar
  Widget _buildNavItem(IconData unselected, IconData selected, String label, int index) {
    bool isSelected = _currentIndex == index;
    // Memanggil warna orange langsung sesuai permintaanmu
    Color activeColor = const Color(0xFFE68C3A);
    Color inactiveColor = Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selected : unselected, 
              color: isSelected ? activeColor : inactiveColor, 
              size: 26
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor, 
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk tombol tengah yang menonjol
  Widget _buildCenterItem(bool isSeller) {
    bool isSelected = _currentIndex == 2;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Tetap orange, tapi beri sedikit bayangan jika terpilih
          color: const Color(0xFFE68C3A),
          shape: BoxShape.circle,
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFE68C3A).withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2
            )
          ] : null,
        ),
        child: Icon(
          isSeller ? Icons.work_outline : Icons.search,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}