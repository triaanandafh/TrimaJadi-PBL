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

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void goToIndex(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  /// Tampilkan dialog guest mode
  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Akun Belum Diverifikasi',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock_outlined,
                  color: Colors.orange.shade700, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kamu dalam mode tamu. Fitur ini hanya tersedia setelah akun diverifikasi oleh admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTalent  = UserData.role.toLowerCase() == 'talent';
    final bool isGuest   = isTalent && !UserData.isVerified;

    final List<Widget> pages = [
      // HOME
      isTalent
          ? HomepageTalent(onViewAll: () => goToIndex(1))
          : HomepageClient(
              onTapSearch: () => goToIndex(2),
              onViewAll  : () => goToIndex(2),
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
              color : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Beranda', 0),
            // Aktivitas — dikunci untuk guest talent
            _buildNavItem(
              Icons.assignment_outlined,
              Icons.assignment,
              'Aktivitas',
              1,
              isLocked: isGuest,
            ),
            _buildCenterItem(isTalent, isGuest: isGuest),
            // Chat — dikunci untuk guest talent
            _buildNavItem(
              Icons.chat_bubble_outline,
              Icons.chat_bubble,
              'Obrolan',
              3,
              isLocked: isGuest,
            ),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profil', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData unselected,
    IconData selected,
    String   label,
    int      index, {
    bool isLocked = false,
  }) {
    final bool  isSelected    = _currentIndex == index;
    const Color activeColor   = Color(0xFFE68C3A);
    const Color inactiveColor = Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showGuestDialog(context);
          return;
        }
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? selected : unselected,
                  color: isLocked
                      ? Colors.grey.shade300
                      : (isSelected ? activeColor : inactiveColor),
                  size: 28,
                ),
                // Ikon gembok kecil di pojok kanan atas
                if (isLocked)
                  Positioned(
                    right: -4,
                    top  : -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock,
                          color: Colors.white, size: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isLocked
                    ? Colors.grey.shade300
                    : (isSelected ? activeColor : inactiveColor),
                fontSize   : 11,
                fontWeight :
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterItem(bool isTalent, {bool isGuest = false}) {
    return GestureDetector(
      onTap: () {
        if (isGuest) {
          _showGuestDialog(context);
          return;
        }
        setState(() => _currentIndex = 2);
      },
      child: Container(
        width : 55,
        height: 55,
        decoration: BoxDecoration(
          color: isGuest
              ? Colors.grey.shade300
              : const Color(0xFFE68C3A),
          shape: BoxShape.circle,
          boxShadow: isGuest
              ? []
              : [
                  BoxShadow(
                    color : const Color(0xFFE68C3A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isTalent ? Icons.business_center : Icons.search,
              color: Colors.white,
              size : 28,
            ),
            if (isGuest)
              Positioned(
                right: 6,
                top  : 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock,
                      color: Colors.white, size: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}