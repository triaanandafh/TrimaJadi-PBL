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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
    });

    try {
      final response = await _supabase
          .from('services')
          .select('''
            id, title, description, image_url,
            users(name, avatar_url),
            service_packages(package_type, price, package_description)
          ''')
          .eq('category_id', widget.categoryId);

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

  Future<void> _searchServices(String query) async {
    // Kalau kosong → tampilkan semua layanan kategori
    if (query.trim().isEmpty) {
      _fetchServices();
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      // Cari berdasarkan judul layanan
      final byTitle = await _supabase
          .from('services')
          .select('''
            id, title, description, image_url,
            users(name, avatar_url),
            service_packages(package_type, price, package_description)
          ''')
          .eq('category_id', widget.categoryId)
          .ilike('title', '%$query%');

      // Cari berdasarkan nama talent
      final talentMatch = await _supabase
          .from('users')
          .select('id')
          .ilike('name', '%$query%')
          .eq('role', 'talent');

      List<Map<String, dynamic>> byTalent = [];

      if (talentMatch.isNotEmpty) {
        final talentIds = talentMatch.map((t) => t['id']).toList();

        final byTalentResponse = await _supabase
            .from('services')
            .select('''
              id, title, description, image_url,
              users(name, avatar_url),
              service_packages(package_type, price, package_description)
            ''')
            .eq('category_id', widget.categoryId)
            .inFilter('user_id', talentIds);

        byTalent = List<Map<String, dynamic>>.from(byTalentResponse);
      }

      // Gabungkan hasil tanpa duplikat
      final Map<String, Map<String, dynamic>> combined = {};

      for (final s in [...byTitle, ...byTalent]) {
        combined[s['id']] = s;
      }

      setState(() {
        _services = combined.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencari layanan: $e')),
        );
      }
    }
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

    return 'Mulai dari Rp ${min.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),

              child: TextField(
                onChanged: _searchServices,

                decoration: InputDecoration(
                  hintText: "Cari layanan atau nama talent...",
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey),

                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchServices('');
                          },
                        )
                      : null,

                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _services.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada layanan di kategori ini',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchServices,

                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 5, 20, 20),

                          itemCount: _services.length,

                          itemBuilder: (context, index) {
                            final service = _services[index];

                            final packages =
                                service['service_packages']
                                        as List<dynamic>? ??
                                    [];

                            final talentName =
                                service['users']?['name'] ??
                                    'Talent';

                            final minPrice =
                                _getMinPrice(packages);

                            return _serviceCard(
                              service: service,
                              talentName: talentName,
                              minPrice: minPrice,
                            );
                          },
                        ),
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
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ServiceDetailPage(service: service),
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
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAMBAR
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),

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

                      child: const Icon(
                        Icons.image,
                        size: 50,
                        color: Color(0xFF1A43BF),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA TALENT
                  Text(
                    talentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // JUDUL LAYANAN
                  Text(
                    service['title'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // HARGA
                  Text(
                    minPrice,
                    style: const TextStyle(
                      color: Color(0xFFE68C3A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
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