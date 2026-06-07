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
      final userId = supabase.auth.currentUser?.id;
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
    // Semua
    if (_selectedFilter == 0) {
      final sorted = [..._orders];
      sorted.sort((a, b) {
        final aWs = a['work_status']    ?? '';
        final bWs = b['work_status']    ?? '';
        final aPs = a['payment_status'] ?? '';
        final bPs = b['payment_status'] ?? '';

        final aIsCancelled = (aWs == 'cancelled' || aPs == 'cancelled') ? 1 : 0;
        final bIsCancelled = (bWs == 'cancelled' || bPs == 'cancelled') ? 1 : 0;

        // Cancelled selalu di bawah
        if (aIsCancelled != bIsCancelled) return aIsCancelled.compareTo(bIsCancelled);

        // Di antara yang tidak cancelled, progress di atas
        final aIsProgress = aWs == 'progress' ? 0 : 1;
        final bIsProgress = bWs == 'progress' ? 0 : 1;
        return aIsProgress.compareTo(bIsProgress);
      });
      return sorted;
    }

    // Aktif — exclude cancelled
    if (_selectedFilter == 1) {
      final filtered = _orders.where((o) {
        final ws = o['work_status']    ?? '';
        final ps = o['payment_status'] ?? '';
        if (ws == 'cancelled' || ps == 'cancelled') return false;
        return ws == 'progress' || ps == 'pending' || ps == 'unpaid';
      }).toList();
      filtered.sort((a, b) {
        final aIsProgress = (a['work_status'] ?? '') == 'progress' ? 0 : 1;
        final bIsProgress = (b['work_status'] ?? '') == 'progress' ? 0 : 1;
        return aIsProgress.compareTo(bIsProgress);
      });
      return filtered;
    }

    // Selesai — exclude cancelled
    if (_selectedFilter == 2) {
      return _orders.where((o) {
        final ws = o['work_status'] ?? '';
        return ws == 'done' || ws == 'accepted';
      }).toList();
    }

    // Dibatalkan
    if (_selectedFilter == 3) {
      return _orders.where((o) {
        final ws = o['work_status']    ?? '';
        final ps = o['payment_status'] ?? '';
        return ws == 'cancelled' || ps == 'cancelled';
      }).toList();
    }

    return _orders;
  }

  /// Resolve label & warna status
  ({String label, Color color}) _resolveStatus(Map<String, dynamic> order) {
    final ws = order['work_status']    ?? '';
    final ps = order['payment_status'] ?? '';

    if (ws == 'cancelled' || ps == 'cancelled')
      return (label: 'Dibatalkan',          color: Colors.red);
    if (ps == 'unpaid')
      return (label: 'Belum Dibayar',       color: Colors.orange);
    if (ps == 'pending')
      return (label: 'Menunggu Bayar',      color: Colors.orange);
    if (ws == 'progress')
      return (label: 'In Progress',         color: Colors.blue);
    if (ws == 'done')
      return (label: 'Menunggu Konfirmasi', color: Colors.teal);
    if (ws == 'accepted')
      return (label: 'Selesai',             color: Colors.green);
    return (label: ws.isEmpty ? '-' : ws,   color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final isTalent = UserData.role.toLowerCase() == 'talent';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          // ── HEADER GRADASI MELENGKUNG ──
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
                bottomLeft:  Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // ── KONTEN SCROLLABLE ──
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
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white),
                                onPressed: _fetchOrders,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // Filter Tabs — scrollable horizontal
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterTab(0, 'Semua'),
                                const SizedBox(width: 10),
                                _filterTab(1, 'Aktif'),
                                const SizedBox(width: 10),
                                _filterTab(2, 'Selesai'),
                                const SizedBox(width: 10),
                                _filterTab(3, 'Dibatalkan'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Area Body — List Order
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // LOADING
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          )

                        // EMPTY
                        else if (_filteredOrders.isEmpty)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _selectedFilter == 3
                                        ? Icons.cancel_outlined
                                        : Icons.inbox_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedFilter == 3
                                        ? 'Tidak ada pesanan yang dibatalkan'
                                        : 'Belum ada order',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )

                        // LIST
                        else
                          Column(
                            children: _filteredOrders.map((order) {
                              final ws        = order['work_status']    ?? '';
                              final ps        = order['payment_status'] ?? '';
                              final orderId   = order['id']?.toString() ?? '';
                              final serviceName = order['service_name'] ?? 'Layanan';
                              final subTitle  = isTalent
                                  ? (order['client_name'] ?? 'Client')
                                  : (order['order_date']  ?? '-');

                              final resolved  = _resolveStatus(order);
                              final isCancelled =
                                  ws == 'cancelled' || ps == 'cancelled';

                              return OrderCard(
                                  title:       serviceName,
                                  subTitle:    subTitle,
                                  status:      resolved.label,
                                  statusColor: resolved.color,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailOrderPage(
                                          orderId:  orderId,
                                          isTalent: isTalent,
                                          status:   ws,
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

    final activeColor = const Color(0xFFE68C3A);

    return ElevatedButton(
      onPressed: () => setState(() => _selectedFilter = index),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? activeColor
            : Colors.white.withOpacity(0.15),
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}