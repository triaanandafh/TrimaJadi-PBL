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
    return min.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15), 
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A237E), // Deep Blue
                Color(0xFF283593), // Indigo
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                onChanged: _searchServices,
                decoration: InputDecoration(
                  hintText: "Cari layanan atau nama talent...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchServices('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none, // Dihapus OutlineInputBorder-nya supaya tidak tabrakan dengan Container
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // LIST AREA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? const Center(child: Text('Belum ada layanan di kategori ini'))
                    : RefreshIndicator(
                        onRefresh: _fetchServices,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            final packages = service['service_packages'] as List<dynamic>? ?? [];
                            final talentName = service['users']?['name'] ?? 'Talent';
                            final talentAvatar = service['users']?['avatar_url']?.toString() ?? '';
                            final minPrice = _getMinPrice(packages);

                            return _serviceCard(
                              service: service,
                              talentName: talentName,
                              talentAvatar: talentAvatar,
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
    required String talentAvatar,
    required String minPrice,
  }) {
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
          borderRadius: BorderRadius.circular(20),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      child: const Icon(Icons.image, size: 50, color: Color(0xFF1A43BF)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                        backgroundImage: talentAvatar.isNotEmpty ? NetworkImage(talentAvatar) : null,
                        child: talentAvatar.isEmpty
                            ? const Icon(Icons.person, size: 16, color: Color(0xFF1A237E))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          talentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 14),
                  _divider(),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mulai Dari",
                            style: TextStyle(
                              color: Color(0xFF9EA8B5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            minPrice == 'Belum ada harga' ? 'Belum ada harga' : 'Rp $minPrice',
                            style: const TextStyle(
                              color: Color(0xFFE68C3A), 
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 36, 
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E), 
                            foregroundColor: Colors.white, 
                            elevation: 0, 
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), 
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceDetailPage(service: service),
                              ),
                            );
                          },
                          child: const Text(
                            "Lihat Detail",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
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

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade100,
      );
}