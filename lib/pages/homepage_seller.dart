import 'package:flutter/material.dart';

class HomeSellerPage extends StatelessWidget {
  const HomeSellerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildOnboardingCard(),
            const SizedBox(height: 25),
            _buildRecentActivityHeader(),
            _buildActivityList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE68C3A), // Orange FAB
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.business_center, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipPath(
          clipper: HeaderClipper(),
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF213E60), // Dark Blue Header
            ),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 65),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF94B6EF), size: 35),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Halo, Tria!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none, color: Color(0xFFE68C3A)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -25,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF94B6EF).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Orderan Kamu",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF213E60)),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildSummaryItem(Icons.account_balance_wallet_outlined, "Pendapatan", "100.000"),
                    Container(height: 35, width: 1, color: const Color(0xFF94B6EF).withOpacity(0.3)),
                    _buildSummaryItem(Icons.description_outlined, "Total Order", "10"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Color(0xFFE68C3A), size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF213E60))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOnboardingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF94B6EF).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mulai dapatkan order pertamamu, Tambahkan jasa dan tampilkan keahlianmu!",
              style: TextStyle(fontSize: 15, color: Color(0xFF213E60), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE68C3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: const Text("Tambah Jasa", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Aktivitas Terakhir",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF213E60)),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF94B6EF))),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      children: [
        _activityItem("Desain Logo Minimalis", "30 April 2026", Icons.palette_outlined),
        _activityItem("Penulisan Artikel", "30 April 2026", Icons.edit_note),
      ],
    );
  }

  Widget _activityItem(String title, String date, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF94B6EF).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFF94B6EF)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF213E60))),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "In Progress",
                style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94B6EF)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, "Beranda", isSelected: true),
          _navItem(Icons.assignment_outlined, "Order"),
          const SizedBox(width: 40),
          _navItem(Icons.chat_bubble_outline_rounded, "Chat"),
          _navItem(Icons.person_outline_rounded, "Profil"),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool isSelected = false}) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFFE68C3A) : Colors.grey.shade400),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE68C3A) : Colors.grey.shade400,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 2, size.height + 15, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}