import 'package:flutter/material.dart';
import 'detail_order_page.dart';
import '../models/user_model.dart';
import '../widgets/order_card.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // State untuk filter yang terpilih (0: Semua, 1: Aktif, 2: Selesai)
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    bool isTalent = UserData.role == "Talent";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Order",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.notifications_none, size: 28),
                ],
              ),
              
              const SizedBox(height: 20),

              // --- SEARCH BAR ---
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- FILTER TABS ---
              Row(
                children: [
                  _filterTab(0, "Semua"),
                  const SizedBox(width: 10),
                  _filterTab(1, "Aktif"),
                  const SizedBox(width: 10),
                  _filterTab(2, "Selesai"),
                ],
              ),

              const SizedBox(height: 30),

              // --- ORDER LIST ---
              // Menampilkan card sesuai Role
              isTalent ? _buildTalentOrders() : _buildClientOrders(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk Tab Filter
  Widget _filterTab(int index, String label) {
    bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A43BF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- TALENT SIDE ---
  Widget _buildTalentOrders() {
   return Column(
      children: [
        OrderCard(
          title: "Desain Logo Minimalis",
          subTitle: "Budiono", // Untuk seller, subTitle kita isi nama client
          status: "Selesai",
          statusColor: Colors.green, // Seller selesai warnanya hijau
          icon: Icons.palette,
          onTap: () {
            print("Tapped Desain Logo Minimalis");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailOrderPage(
                isTalent: UserData.role == "Talent",
                status: "done",
              )),
            );
          },
        ),
      ],
    );
  }

  // --- CLIENT SIDE ---
  Widget _buildClientOrders() {
    return Column(
      children: [
        OrderCard(
          title: "Desain Logo Minimalis",
          subTitle: "30 April 2026", // Untuk client, subTitle kita isi tanggal
          status: "In Progress",
          statusColor: Colors.red, // Client in progress warnanya merah
        ),
        OrderCard(
          title: "Desain Poster",
          subTitle: "30 April 2026",
          status: "In Progress",
          statusColor: Colors.red,
        ),
      ],
    );
  }

  
}