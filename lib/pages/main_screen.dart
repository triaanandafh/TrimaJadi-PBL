import 'package:flutter/material.dart';
import 'package:trimajadi/pages/chat_list_page.dart';
import 'package:trimajadi/pages/talent_service_page.dart';
import 'package:trimajadi/pages/talent_home_page.dart';
import '../models/user_model.dart';
import 'client_home_page.dart';
import 'profile_page.dart';
import 'search_service_page.dart';
import 'order_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

// MainScreenState dipublish (bukan _MainScreenState) supaya bisa direferensi jika perlu.
class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void goToIndex(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTalent = UserData.role.toLowerCase() == 'talent';

    final List<Widget> pages = [
      // HOME
      isTalent
          ? HomepageTalent(onViewAll: () => goToIndex(1))
          : HomepageClient(
              onTapSearch: () => goToIndex(2),
            ),

      // AKTIVITAS
      const OrderPage(),

      // CENTER PAGE
      isTalent ? const LayananPage() : const CariLayananPage(),

      // CHAT
      const ChatListPage(),

      // PROFIL
      ProfilePage(onNavigate: goToIndex),
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
            _buildNavItem(Icons.home_outlined, Icons.home, 'Beranda', 0),
            _buildNavItem(
                Icons.assignment_outlined, Icons.assignment, 'Aktivitas', 1),
            _buildCenterItem(isTalent),
            _buildNavItem(
                Icons.chat_bubble_outline, Icons.chat_bubble, 'Obrolan', 3),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profil', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData unselected, IconData selected, String label, int index) {
    final bool isSelected = _currentIndex == index;
    const Color activeColor   = Color(0xFFE68C3A);
    const Color inactiveColor = Color(0xFF9E9E9E);

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

  Widget _buildCenterItem(bool isTalent) {
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
          isTalent ? Icons.business_center : Icons.search,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
