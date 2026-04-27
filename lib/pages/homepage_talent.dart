import 'package:flutter/material.dart';
import '../widgets/order_card.dart';

class HomepageTalent extends StatelessWidget {
  const HomepageTalent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 60),
            _buildOnboardingCard(),
            const SizedBox(height: 25),
            _buildRecentActivityHeader(),
            _buildActivityList(),
          ],
        ),
      ),
      
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   backgroundColor: const Color(0xFFE68C3A), // Orange FAB
      //   elevation: 4,
      //   shape: const CircleBorder(),
      //   child: const Icon(Icons.business_center, color: Colors.white),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // 1. Bagian Biru Header
      Container(
        height: 220,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1E3A8A),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, top: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Halo, Tria!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,),
                    child: const Icon(Icons.notifications_none, color: Color(0xFFE68C3A)),
                ),
                  ],
                ),
            const SizedBox(height: 30),
            const Text(
                "Orderan Kamu",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              ],
            ),
          ),
        ),
      ),

      // 2. Card Orderan Kamu (Positioned)
      Positioned(
        bottom: -35,
        left: 25,
        right: 25,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF94B6EF).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildSummaryItem(Icons.account_balance_wallet_outlined, "Pendapatan", "100.000", bgColor: const Color(0xFFFFF7ED), // Warna soft orange
                    iconColor: const Color(0xFFEA580C),),
                  Container(height: 45, width: 1, color: const Color(0xFF94B6EF).withOpacity(0.3)),
                  _buildSummaryItem(Icons.description_outlined, "Total Order", "10", bgColor: const Color(0xFFEFF6FF), // Warna soft orange
                    iconColor: const Color(0xFF2563EB),),
                ], // Tutup Row
              ), // Tutup Row
            ], // Tutup Children Column (Ini yang tadi hilang!)
          ), // Tutup Column
        ), // Tutup Container
      ), // Tutup Positioned
    ], // Tutup Children Stack
  ); // Tutup Stack
}

  Widget _buildSummaryItem(IconData icon, String label, String value, {required Color bgColor, required Color iconColor}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          // Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF213E60))),
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
        OrderCard(
  title: "Desain Logo Minimalis",
  subTitle: "30 April 2026",
  status: "In Progress",
),
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

  // Widget _buildBottomNav() {
  //   return BottomAppBar(
  //     color: Colors.white,
  //     shape: const CircularNotchedRectangle(),
  //     notchMargin: 8,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _navItem(Icons.home_rounded, "Beranda", isSelected: true),
  //         _navItem(Icons.assignment_outlined, "Order"),
  //         const SizedBox(width: 40),
  //         _navItem(Icons.chat_bubble_outline_rounded, "Chat"),
  //         _navItem(Icons.person_outline_rounded, "Profil"),
  //       ],
  //     ),
  //   );
  // }

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