import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trimajadi/pages/service_detail_page.dart';

class ServiceListPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ServiceListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('services')
          .select('''
            id, title, description, image_url, is_featured, featured_order, user_id,
            users(id, name, avatar_url, is_verified),
            service_packages(package_type, price, package_description)
          ''')
          .eq('category_id', widget.categoryId)
          .or('title.ilike.%$_searchQuery%,talent_name.ilike.%$_searchQuery%')
          .order('featured_order', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false);

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

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      final talentName = (s['users']?['name'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) ||
          talentName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getMinPrice(List<dynamic> packages) {
    if (packages.isEmpty) return 'Belum ada harga';
    final prices = packages
        .where((p) => p['price'] != null)
        .map((p) => (p['price'] as num).toDouble())
        .toList();
    if (prices.isEmpty) return 'Belum ada harga';
    prices.sort();
    final min = prices.first;
    return 'Rp ${min.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          // Header biru
          Container(
            height: 110,
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
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tombol Back
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: const CircleBorder(),
                      ),
                    ),

                    // Judul di Tengah
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          widget.categoryName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Spacer dummy agar judul presisi di tengah
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Konten
          Padding(
            padding: const EdgeInsets.only(top: 110),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: "Cari layanan atau nama talent...",
                        hintStyle: TextStyle(color: Color.fromARGB(255, 187, 187, 187)),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredServices.isEmpty
                          ? const Center(
                              child: Text('Belum ada layanan di kategori ini'))
                          : RefreshIndicator(
                              onRefresh: _fetchServices,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 5, 20, 20),
                                itemCount: _filteredServices.length,
                                itemBuilder: (context, index) {
                                  final service = _filteredServices[index];
                                  final packages =
                                      service['service_packages'] as List<dynamic>? ?? [];
                                  final talentName =
                                      service['users']?['name'] ?? 'Talent';
                                  final minPrice = _getMinPrice(packages);
                                  final isFeatured =
                                      service['is_featured'] == true;

                                  return _serviceCard(
                                    service: service,
                                    talentName: talentName,
                                    minPrice: minPrice,
                                    isFeatured: isFeatured,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required Map<String, dynamic> service,
    required String talentName,
    required String minPrice,
    required bool isFeatured,
  }) {
    final avatarUrl = service['users']?['avatar_url']?.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailPage(service: service),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15)),
                  child: service['image_url'] != null
                      ? Image.network(
                          service['image_url'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 150,
                          width: double.infinity,
                          color: const Color(0xFFE8F0FF),
                          child: const Icon(Icons.image,
                              size: 50, color: Color(0xFF1A43BF)),
                        ),
                ),
                if (isFeatured)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE68C3A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Recommended',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + Nama talent
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFE8EAF6),
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person,
                                size: 16, color: Color(0xFF3F51B5))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        talentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF213E60),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Judul layanan
                  Text(
                    service['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  // Harga + tombol
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MULAI DARI',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            minPrice,
                            style: const TextStyle(
                              color: Color(0xFFE68C3A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ServiceDetailPage(service: service),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}