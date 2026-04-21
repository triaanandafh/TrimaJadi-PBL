import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'homepage_client.dart';
import 'homepage_seller.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    UserData.role == "Seller" ? HomepageSeller() : HomepageClient(), 
    Center(child: Text("Halaman Tugas")),
    Center(child: Text("Halaman Cari")),
    Center(child: Text("Halaman Chat")),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          _buildNavBarItem(Icons.home_outlined, Icons.home, 0),
          _buildNavBarItem(Icons.assignment_outlined, Icons.assignment, 1),
          _buildNavBarItem(Icons.search, Icons.search, 2),
          _buildNavBarItem(Icons.chat_bubble_outline, Icons.chat_bubble, 3),
          _buildNavBarItem(Icons.person_outline, Icons.person, 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavBarItem(IconData unselected, IconData selected, int index) {
    bool isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFE68C3A) : Colors.transparent, shape: BoxShape.circle),
        child: Icon(isSelected ? selected : unselected, color: isSelected ? Colors.white : Colors.grey, size: 26),
      ),
      label: '',
    );
  }
}