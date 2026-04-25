import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'homepage_client.dart';
import 'homepage_seller.dart';
import 'profile_page.dart';
import 'searching_page.dart';
import 'order_page.dart';
import 'cari_layanan.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isSeller = UserData.role == "Seller";

    final List<Widget> pages = [
      isSeller 
        ? const HomeSellerPage() 
        : HomepageClient(
            onTapSearch: () {
              setState(() {
                _currentIndex = 2; 
              });
            },
          ), 
      
      const Center(child: Text("Order")),
      
      isSeller 
          ? const Center() 
          : const CariLayananPage(), 
      
      const Center(child: Text("Chat")),
      const ProfilePage(),
    ];

    return Scaffold(
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5), 
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, "Beranda", 0),
            _buildNavItem(Icons.assignment_outlined, Icons.assignment, "Order", 1),
            _buildCenterItem(isSeller), 
            _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, "Chat", 3),
            _buildNavItem(Icons.person_outline, Icons.person, "Profil", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData unselected, IconData selected, String label, int index) {
    bool isSelected = _currentIndex == index;
    Color activeColor = const Color(0xFFE68C3A);
    Color inactiveColor = const Color(0xFF9E9E9E);

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
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor, 
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterItem(bool isSeller) {
    bool isSelected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFE68C3A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE68C3A).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isSeller ? Icons.business_center : Icons.search,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}