import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trimajadi/pages/add_service_page.dart';
import 'package:trimajadi/pages/edit_service_page.dart';
import 'package:trimajadi/pages/payment_page.dart';

class LayananPage extends StatefulWidget {
  const LayananPage({super.key});

  @override
  State<LayananPage> createState() => _LayananPageState();
}

class _LayananPageState extends State<LayananPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('services')
          .select('''
            id, title, description, category_id, image_url, is_featured,
            categories(name),
            service_packages(id, package_type, package_description, price)
          ''')
          .eq('user_id', userId);

      setState(() {
        _services = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat layanan: $e')),
        );
      }
    }
  }

  Future<void> _deleteService(Map<String, dynamic> service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Yakin ingin menghapus layanan ini? Aksi ini tidak bisa dibatalkan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A43BF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                    color: Color(0xFF1A43BF), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final serviceId = service['id'];
      await _supabase
          .from('service_packages')
          .delete()
          .eq('service_id', serviceId);
      await _supabase.from('services').delete().eq('id', serviceId);
      _fetchServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  Future<void> _showPromoDialog(Map<String, dynamic> service) async {
    // Cek apakah layanan ini sudah ada promo pending/approved
    final existing = await _supabase
        .from('promotion_requests')
        .select()
        .eq('service_id', service['id'])
        .inFilter('status', ['pending', 'approved']).maybeSingle();

    if (existing != null && mounted) {
      final status = existing['status'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'pending'
                ? 'Layanan ini sedang menunggu persetujuan admin'
                : 'Layanan ini sudah aktif dipromosikan',
          ),
          backgroundColor: const Color(0xFF1A237E),
        ),
      );
      return;
    }

    // Ambil category_id & nama kategori dari service
    final categoryId = service['category_id'];
    final categoryName = service['categories']?['name'] ?? 'kategori ini';

    // Cek slot per kategori
    final approvedResult = await _supabase
        .from('promotion_requests')
        .select()
        .eq('status', 'approved')
        .eq('category_id', categoryId)
        .count();

    final approvedCount = approvedResult.count;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Promosikan Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rocket_launch,
                      color: Color(0xFF1A237E), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    service['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _promoInfoRow('Durasi', '28 hari'),
                  const SizedBox(height: 4),
                  _promoInfoRow('Harga', 'Rp 50.000'),
                  const SizedBox(height: 4),
                  _promoInfoRow(
                    'Slot "$categoryName"',
                    '${3 - approvedCount} / 3',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pembayaran akan ditahan hingga disetujui admin. Jika ditolak, dana dikembalikan ke wallet kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A237E)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Batal',
                  style: TextStyle(color: Color(0xFF1A237E))),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: approvedCount >= 3
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChoosePaymentPage(
                            orderId: service['id'],
                            totalPrice: 50000,
                            serviceName: service['title'] ?? '',
                            clientName: '',
                            isPromotion: true,
                            categoryId: service['category_id'],
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: approvedCount >= 3
                    ? Colors.grey
                    : const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                approvedCount >= 3 ? 'Slot Penuh' : 'Lanjut Bayar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '-';
    final p = (price as num).toDouble();
    return 'Rp ${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Map<String, dynamic>? _getPackage(List<dynamic> packages, String type) {
    try {
      return packages.firstWhere((p) => p['package_type'] == type);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9),
      body: Stack(
        children: [
          // Header biru
          Container(
            height: 150,
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
                child: const Text(
                  'Layanan Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Konten list
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.work_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada layanan',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + untuk menambahkan layanan pertamamu',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchServices,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 10, 20, 100),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            final categoryName =
                                service['categories']?['name'] ?? 'Kategori';
                            final packages =
                                service['service_packages']
                                    as List<dynamic>? ??
                                    [];
                            final basic = _getPackage(packages, 'basic');
                            final standard =
                                _getPackage(packages, 'standard');
                            final premium =
                                _getPackage(packages, 'premium');

                            return _serviceItem(
                              context,
                              service: service,
                              categoryName: categoryName,
                              basic: basic,
                              standard: standard,
                              premium: premium,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE68C3A),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddServicePage()),
          );
          _fetchServices();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _serviceItem(
    BuildContext context, {
    required Map<String, dynamic> service,
    required String categoryName,
    required Map<String, dynamic>? basic,
    required Map<String, dynamic>? standard,
    required Map<String, dynamic>? premium,
  }) {
    final isFeatured = service['is_featured'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isFeatured
              ? const Color(0xFFE68C3A).withOpacity(0.4)
              : Colors.grey[100]!,
          width: isFeatured ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge featured
          if (isFeatured)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE68C3A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Color(0xFFE68C3A), size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Sedang Dipromosikan',
                    style: TextStyle(
                      color: Color(0xFFE68C3A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Konten utama: kiri (info) | garis | kanan (tombol)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kiri: thumbnail + judul + harga
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail + judul
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(12),
                            image: service['image_url'] != null
                                ? DecorationImage(
                                    image:
                                        NetworkImage(service['image_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: service['image_url'] == null
                              ? const Icon(Icons.image,
                                  color: Color(0xFF1A43BF))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryName,
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service['title'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // Harga paket
                    Row(
                      children: [
                        _packagePrice(
                            'Basic', basic?['price'], Colors.blue),
                        _packagePrice(
                            'Standard', standard?['price'], Colors.orange),
                        _packagePrice(
                            'Premium', premium?['price'], Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),

              // Garis pemisah vertikal
              Container(
                width: 1,
                height: 110,
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),

              // Kanan: tombol aksi vertikal
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionButton(
                    icon: Icons.rocket_launch_outlined,
                    color: isFeatured
                        ? const Color(0xFFE68C3A)
                        : const Color(0xFF1A237E),
                    tooltip: 'Promosikan',
                    onTap: () => _showPromoDialog(service),
                  ),
                  _actionButton(
                    icon: Icons.edit_note,
                    color: Colors.grey,
                    tooltip: 'Edit',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditServicePage(service: service),
                        ),
                      );
                      _fetchServices();
                    },
                  ),
                  _actionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    tooltip: 'Hapus',
                    onTap: () => _deleteService(service),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }

  Widget _packagePrice(String label, dynamic price, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            _formatPrice(price),
            style:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}