import 'package:flutter/material.dart';
import 'package:trimajadi/pages/chat_list_page.dart';
import 'package:trimajadi/pages/talent_service_page.dart';
import '../models/user_model.dart';
import 'client_home_page.dart';
import 'talent_home_page.dart';
import 'profile_page.dart';
import 'search_service_page.dart';
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
    bool isTalent = UserData.role == "Talent";

    final List<Widget> pages = [
      // HOME
      isTalent
          ? const HomepageTalent()
          : HomepageClient(
              onTapSearch: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),

      // ORDER
      const OrderPage(
      ),

      // CENTER PAGE
      isTalent
          ? const LayananPage()
          : const CariLayananPage(),

      // CHAT
      const ChatListPage(),

      // PROFILE
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
            _buildNavItem(
              Icons.home_outlined,
              Icons.home,
              "Beranda",
              0,
            ),
            _buildNavItem(
              Icons.assignment_outlined,
              Icons.assignment,
              "Order",
              1,
            ),
            _buildCenterItem(isTalent),
            _buildNavItem(
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
              "Chat",
              3,
            ),
            _buildNavItem(
              Icons.person_outline,
              Icons.person,
              "Profil",
              4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData unselected,
    IconData selected,
    String label,
    int index,
  ) {
    bool isSelected = _currentIndex == index;

    Color activeColor = const Color(0xFFE68C3A);
    Color inactiveColor = const Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
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
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterItem(bool isTalent) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
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
          isTalent ? Icons.business_center : Icons.search,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}