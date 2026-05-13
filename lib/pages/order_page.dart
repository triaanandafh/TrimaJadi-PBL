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

  int _selectedFilter = 0;
  bool _isLoading = true;
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
      final isTalent = UserData.role == 'Talent';

      final response = await supabase
          .from('orders')
          .select()
          .eq(isTalent ? 'talent_id' : 'client_id', userId ?? '')
          .order('created_at', ascending: false);

      setState(() => _orders = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat order: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final isTalent = UserData.role == 'Talent';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchOrders,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                      'Order',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchOrders,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- FILTER TABS ---
                Row(
                  children: [
                    _filterTab(0, 'Semua'),
                    const SizedBox(width: 10),
                    _filterTab(1, 'Aktif'),
                    const SizedBox(width: 10),
                    _filterTab(2, 'Selesai'),
                  ],
                ),

                const SizedBox(height: 24),

                // --- LOADING ---
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

                // --- ORDER LIST ---
                else
                  Column(
                    children: _filteredOrders.map((order) {
                      final workStatus    = order['work_status']    ?? 'pending';
                      final paymentStatus = order['payment_status'] ?? 'unpaid';
                      final serviceName   = order['service_name']   ?? 'Layanan';
                      final orderId       = order['id']?.toString() ?? '';

                      String statusLabel;
                      Color  statusColor;
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
                        title      : serviceName,
                        subTitle   : subTitle,
                        status     : statusLabel,
                        statusColor: statusColor,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailOrderPage(
                                orderId  : orderId,
                                isTalent : isTalent,
                                status   : workStatus,
                              ),
                            ),
                          );
                          _fetchOrders();
                        },
                      );
                    }).toList(),
                  ),

                // ===== TOMBOL TEST PAYMENT — HAPUS KALAU SUDAH LIVE =====
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🧪 Mode Testing',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Buat order dummy untuk test pembayaran Duitku sandbox.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C4A6E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _createDummyOrder,
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                          label: const Text(
                            'Buat Order Test & Bayar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ===== END TOMBOL TEST =====

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== BUAT ORDER DUMMY UNTUK TESTING =====
  Future<void> _createDummyOrder() async {
    try {
      final userId   = supabase.auth.currentUser?.id;
      final isTalent = UserData.role == 'Talent';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await supabase.from('orders').insert({
        'client_id'     : userId,
        'talent_id'     : userId,
        'service_name'  : 'Desain Logo Test #$timestamp',
        'duration'      : 3,
        'order_date'    : DateTime.now().toIso8601String().substring(0, 10),
        'deadline'      : DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String()
            .substring(0, 10),
        'total_price'   : 50000,
        'payment_status': 'unpaid',
        'work_status'   : 'pending',
        'description'   : 'Order dummy untuk testing pembayaran Duitku sandbox.',
      }).select().single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order test dibuat! Tap Bayar Sekarang.'),
            backgroundColor: Colors.green,
          ),
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailOrderPage(
              orderId  : response['id'].toString(),
              isTalent : isTalent,
              status   : 'pending',
            ),
          ),
        );

        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal buat order test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _filterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A43BF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
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
}
