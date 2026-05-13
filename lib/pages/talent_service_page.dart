import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trimajadi/pages/add_service_page.dart';
import 'package:trimajadi/pages/edit_service_page.dart';

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
            id, title, description, category_id, image_url,
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
        title: const Text('Hapus Layanan',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: const Text(
            'Yakin ingin menghapus layanan ini? Aksi ini tidak bisa dibatalkan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey)),
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
              child: const Text('Batal',
                  style: TextStyle(
                      color: Color(0xFF1A43BF),
                      fontWeight: FontWeight.w600)),
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
              child: const Text('Hapus',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
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
          const SnackBar(content: Text("Layanan berhasil dihapus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus: $e")),
        );
      }
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Layanan Saya",
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('Belum ada layanan'))
              : RefreshIndicator(
                  onRefresh: _fetchServices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final categoryName =
                          service['categories']?['name'] ?? 'Kategori';
                      final packages =
                          service['service_packages'] as List<dynamic>? ?? [];

                      final basic = _getPackage(packages, 'basic');
                      final standard = _getPackage(packages, 'standard');
                      final premium = _getPackage(packages, 'premium');

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE68C3A),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddServicePage()),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: thumbnail + judul + tombol
          Row(
            children: [
              // Thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(12),
                  image: service['image_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(service['image_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: service['image_url'] == null
                    ? const Icon(Icons.image, color: Color(0xFF1A43BF))
                    : null,
              ),
              const SizedBox(width: 15),
              // Judul & Kategori
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryName,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12)),
                    Text(service['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              // Tombol Edit & Hapus
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditServicePage(service: service),
                        ),
                      );
                      _fetchServices();
                    },
                    icon: const Icon(Icons.edit_note, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () => _deleteService(service),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Harga per paket
          Row(
            children: [
              _packagePrice('Basic', basic?['price'], Colors.blue),
              _packagePrice('Standard', standard?['price'], Colors.orange),
              _packagePrice('Premium', premium?['price'], Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _packagePrice(String label, dynamic price, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(
            _formatPrice(price),
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}