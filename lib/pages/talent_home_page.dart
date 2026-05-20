import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trimajadi/pages/notification_page.dart';
import '../widgets/order_card.dart';
import 'add_service_page.dart';
import 'detail_order_page.dart';
import '../models/user_model.dart';

class HomepageTalent extends StatefulWidget {
  /// Callback dipanggil saat user tap "Lihat Semua" → navigasi ke tab Aktivitas
  final VoidCallback? onViewAll;

  const HomepageTalent({super.key, this.onViewAll});

  @override
  State<HomepageTalent> createState() => _HomepageTalentState();
}

class _HomepageTalentState extends State<HomepageTalent> {
  final supabase = Supabase.instance.client;

  bool _isLoading       = true;
  int  _totalOrder      = 0;
  int  _totalPendapatan = 0;
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final orders = await supabase
          .from('orders')
          .select()
          .eq('talent_id', userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(orders);

      final total = list.length;
      final pendapatan = list
          .where((o) => o['work_status'] == 'accepted')
          .fold<int>(
              0, (sum, o) => sum + ((o['talent_earning'] as num?)?.toInt() ?? 0));
      final recent = list.take(5).toList();

      setState(() {
        _totalOrder      = total;
        _totalPendapatan = pendapatan;
        _recentOrders    = recent;
        _isLoading       = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(int value) {
    final str    = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 60),
              _buildOnboardingCard(context),
              const SizedBox(height: 25),
              _buildRecentActivityHeader(context),
              _buildActivityList(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===== HEADER =====
  Widget _buildHeader(BuildContext context) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // 1. Bagian Biru Header
      Container(
        height: 220,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), // Deep Blue (Profil kamu)
              Color(0xFF283593), // Indigo yang lebih terang
              Color(0xFF3949AB), // Light Indigo (Orderan kamu)
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
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            backgroundImage: UserData.avatarUrl.isNotEmpty
                                ? NetworkImage(UserData.avatarUrl)
                                : null,
                            child: UserData.avatarUrl.isEmpty
                                ? const Icon(Icons.person,
                                    color: Colors.white, size: 24)
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Text(
                            'Halo, ${UserData.name}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none,
                              color: Color(0xFFE68C3A)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Orderan Kamu',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Card ringkasan
        Positioned(
          bottom: -35,
          left: 25,
          right: 25,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF94B6EF).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    children: [
                      _buildSummaryItem(
                        Icons.account_balance_wallet_outlined,
                        'Pendapatan',
                        'Rp ${_formatRupiah(_totalPendapatan)}',
                        bgColor: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFEA580C),
                      ),
                      Container(
                          height: 45,
                          width: 1,
                          color: const Color(0xFF94B6EF).withOpacity(0.3)),
                      _buildSummaryItem(
                        Icons.description_outlined,
                        'Total Order',
                        '$_totalOrder',
                        bgColor: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String label,
    String value, {
    required Color bgColor,
    required Color iconColor,
  }) {
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF213E60))),
            ],
          ),
        ],
      ),
    );
  }

  // ===== ONBOARDING CARD =====
  Widget _buildOnboardingCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: const Color(0xFF94B6EF).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mulai dapatkan order pertamamu, Tambahkan jasa dan tampilkan keahlianmu!',
              style: TextStyle(
                  fontSize: 15, color: Color(0xFF213E60), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddServicePage()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE68C3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 25, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: const Text('Tambah Jasa',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ===== AKTIVITAS TERAKHIR =====
  Widget _buildRecentActivityHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Aktivitas Terakhir',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF213E60)),
          ),
          TextButton(
            onPressed: widget.onViewAll,
            child: const Text('Lihat Semua',
                style: TextStyle(color: Color(0xFF94B6EF))),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recentOrders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 50, color: Colors.grey[300]),
              const SizedBox(height: 10),
              Text(
                'Belum ada aktivitas',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: _recentOrders.length,
      itemBuilder: (ctx, index) {
        final order         = _recentOrders[index];
        final workStatus    = order['work_status']    ?? 'pending';
        final paymentStatus = order['payment_status'] ?? 'unpaid';
        final serviceName   = order['service_name']   ?? 'Layanan';
        final orderId       = order['id']?.toString() ?? '';
        final clientName    = order['client_name']?.toString() ?? 'Client';

        String statusLabel;
        Color  statusColor;
        if (paymentStatus == 'unpaid' || paymentStatus == 'pending') {
          statusLabel = 'Menunggu Bayar';
          statusColor = Colors.orange;
        } else if (workStatus == 'progress') {
          statusLabel = 'In Progress';
          statusColor = Colors.blue;
        } else if (workStatus == 'done') {
          statusLabel = 'Menunggu Konfirmasi';
          statusColor = Colors.teal;
        } else if (workStatus == 'accepted') {
          statusLabel = 'Selesai';
          statusColor = Colors.green;
        } else {
          statusLabel = workStatus;
          statusColor = Colors.grey;
        }

        return OrderCard(
          title      : serviceName,
          subTitle   : clientName,   // ← nama client, bukan tanggal
          status     : statusLabel,
          statusColor: statusColor,
          onTap: () async {
            await Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => DetailOrderPage(
                  orderId : orderId,
                  isTalent: true,
                  status  : workStatus,
                ),
              ),
            );
            _fetchDashboardData();
          },
        );
      },
    );
  }
}
