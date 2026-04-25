import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'homepage_client.dart';
import 'homepage_seller.dart';
import 'profile_page.dart';
import 'searching_page.dart';
import 'order_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      UserData.role == "Talent" ? HomepageSeller() : HomepageClient(
        onTapSearch: () => setState(() => _currentIndex = 2),
      ),
      const OrderPage(),
      UserData.role == "Talent" ? const Center(child: Text("Post Jasa")) : SearchingClient(),
      Center(child: Text("Halaman Chat")),
      ProfilePage(),
    ];

    bool isSeller = UserData.role == "Talent";

    return Scaffold(
      body: pages[_currentIndex], 
      
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
    Color color = isSelected ? const Color(0xFFE68C3A) : Colors.grey;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selected : unselected, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterItem(bool isSeller) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFE68C3A),
          shape: BoxShape.circle,
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