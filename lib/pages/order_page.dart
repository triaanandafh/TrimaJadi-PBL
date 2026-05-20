import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_order_page.dart';
import '../models/user_model.dart';
import '../widgets/order_card.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final supabase = Supabase.instance.client;

  int  _selectedFilter = 0;
  bool _isLoading      = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final userId   = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final isTalent = UserData.role.toLowerCase() == 'talent';

      final response = await supabase
          .from('orders')
          .select()
          .eq(isTalent ? 'talent_id' : 'client_id', userId)
          .order('created_at', ascending: false);

      setState(() => _orders = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 0) return _orders;
    if (_selectedFilter == 1) {
      return _orders.where((o) {
        final ws = o['work_status']    ?? '';
        final ps = o['payment_status'] ?? '';
        return ws == 'progress' || ps == 'pending' || ps == 'unpaid';
      }).toList();
    }
    return _orders.where((o) {
      final ws = o['work_status'] ?? '';
      return ws == 'done' || ws == 'accepted';
    }).toList();
  }

  /// Label & warna status berdasarkan payment_status + work_status
  ({String label, Color color}) _resolveStatus(Map<String, dynamic> order) {
    final ws = order['work_status']    ?? '';
    final ps = order['payment_status'] ?? '';

    if (ps == 'unpaid')  return (label: 'Belum Dibayar',        color: Colors.orange);
    if (ps == 'pending') return (label: 'Menunggu Bayar',        color: Colors.orange);
    if (ws == 'progress') return (label: 'In Progress',          color: Colors.blue);
    if (ws == 'done')     return (label: 'Menunggu Konfirmasi',  color: Colors.teal);
    if (ws == 'accepted') return (label: 'Selesai',              color: Colors.green);
    return (label: ws.isEmpty ? '-' : ws, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final isTalent = UserData.role.toLowerCase() == 'talent';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          // 1. HEADER GRADASI MELENGKUNG
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                  Color(0xFF3949AB),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // 2. KONTEN SCROLLABLE + REFRESH INDICATOR
          RefreshIndicator(
            onRefresh: _fetchOrders,
            color: const Color(0xFF1A237E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Area Header
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Aktivitas',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_orders.length} order kamu',
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                onPressed: _fetchOrders,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // Filter Tabs
                          Row(
                            children: [
                              _filterTab(0, 'Semua'),
                              const SizedBox(width: 10),
                              _filterTab(1, 'Aktif'),
                              const SizedBox(width: 10),
                              _filterTab(2, 'Selesai'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Area Body Utama (List Order)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // --- LOADING STATE ---
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )

                        // --- EMPTY STATE ---
                        else if (_filteredOrders.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada order',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )

                        // --- LIST DATA ORDER ---
                        else
                          Column(
                            children: _filteredOrders.map((order) {
                              final workStatus    = order['work_status']    ?? 'pending';
                              final paymentStatus = order['payment_status'] ?? 'unpaid';
                              final serviceName   = order['service_name']   ?? 'Layanan';
                              final orderId       = order['id']?.toString() ?? '';

                              String statusLabel;
                              Color statusColor;
                              if (paymentStatus == 'unpaid') {
                                statusLabel = 'Belum Dibayar';
                                statusColor = Colors.orange;
                              } else if (paymentStatus == 'pending') {
                                statusLabel = 'Menunggu Bayar';
                                statusColor = Colors.orange;
                              } else if (workStatus == 'progress') {
                                statusLabel = 'In Progress';
                                statusColor = Colors.blue;
                              } else if (workStatus == 'done' || workStatus == 'accepted') {
                                statusLabel = 'Selesai';
                                statusColor = Colors.green;
                              } else {
                                statusLabel = workStatus;
                                statusColor = Colors.grey;
                              }

                              final subTitle = isTalent
                                  ? (order['client_name'] ?? 'Client')
                                  : (order['order_date']  ?? '-');

                              return OrderCard(
                                title: serviceName,
                                subTitle: subTitle,
                                status: statusLabel,
                                statusColor: statusColor,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailOrderPage(
                                        orderId: orderId,
                                        isTalent: isTalent,
                                        status: workStatus,
                                      ),
                                    ),
                                  );
                                  _fetchOrders();
                                },
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE68C3A) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
