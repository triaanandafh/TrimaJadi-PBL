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

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services.where((s) {
      final title = (s['title'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
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
    return min.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(widget.categoryName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold,)
                ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15), // Putih transparan 15%
              // shape: const CircleShape(), // Memastikan bentuknya lingkaran sempurna
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Cari layanan di kategori ini...",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: const Color(0xFFF2F5FA),
                  
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Angka 25-30 akan membuatnya membulat (pill-shaped)
                  borderSide: BorderSide.none, // Menghilangkan garis hitam di tepi luar
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
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
                                service['service_packages'] as List<dynamic>? ??
                                    [];
                            final talentName =
                                service['users']?['name'] ?? 'Talent';
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
                color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                  // Nama talent
                  const SizedBox(height: 10),
                  // Judul layanan
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
                    // alignment: Alignment.bottomCenter,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mulai Dari",
                            style: TextStyle(
                              color: Color.fromARGB(255, 158, 168, 181),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            minPrice == '0' ? 'Belum ada harga' : 'Rp $minPrice',
                            style: const TextStyle(
                              color: Color(0xFFE68C3A), // Jingga emas khas TrimaJadi
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 36, // Ukuran tombol yang pas dan proposional
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E), // Biru Utama sesuai tema
                            foregroundColor: Colors.white, // Warna teks putih bersih
                            elevation: 0, // Flat design modern
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Melengkung serasi dengan border card
                            ),
                          ),
                          onPressed: () {
                            // Memicu fungsi navigasi yang sama saat tombol diklik
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

class CircleShape {
  const CircleShape(

  );
}