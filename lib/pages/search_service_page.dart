import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trimajadi/pages/service_list_page.dart';

class CariLayananPage extends StatefulWidget {
  const CariLayananPage({super.key});

  @override
  State<CariLayananPage> createState() => _CariLayananPageState();
}

class _CariLayananPageState extends State<CariLayananPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('services')
          .select('''
            id, title, description, image_url,
            categories(name),
            users(name),
            service_packages(package_type, price)
          ''')
          .ilike('title', '%$query%');

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencari: $e')),
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
    return 'Mulai dari Rp ${min.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Cari Layanan",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.notifications_none_outlined, size: 30),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _search,
                            decoration: InputDecoration(
                              hintText: "Search",
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _isSearching
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        _search('');
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
                      const SizedBox(width: 15),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.tune, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Konten: hasil search atau list kategori
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildCategoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Layanan tidak ditemukan'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final service = _searchResults[index];
        final talentName = service['users']?['name'] ?? 'Talent';
        final categoryName = service['categories']?['name'] ?? '';
        final packages = service['service_packages'] as List<dynamic>? ?? [];
        final minPrice = _getMinPrice(packages);

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
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
                    const BorderRadius.vertical(top: Radius.circular(15)),
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
                    // Kategori
                    Text(categoryName,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11)),
                    const SizedBox(height: 2),
                    // Judul
                    Text(service['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    // Talent
                    Text(talentName,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 6),
                    // Harga
                    Text(minPrice,
                        style: const TextStyle(
                            color: Color(0xFFE68C3A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          _buildCategoryCard(
            context,
            categoryId: '34b4a9b2-2b77-4ce3-afc9-7a119212d6b3',
            title: "Desain",
            subtitle: "Logo, seni, dan ilustrasi",
            icon: Icons.palette,
            bgColor: const Color(0xFFE3F2FD),
            iconColor: Colors.blue,
          ),
          _buildCategoryCard(
            context,
            categoryId: '631f54e5-5a7f-4626-8d11-e8a75efc1ac7',
            title: "Web & Pemrograman",
            subtitle: "Pengembangan Website",
            icon: Icons.code,
            bgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE68C3A),
          ),
          _buildCategoryCard(
            context,
            categoryId: 'ae281474-8aec-4ae5-94d8-edbaba273e6d',
            title: "Edukasi",
            subtitle: "Bimbingan belajar, tugas, mentoring",
            icon: Icons.school,
            bgColor: const Color(0xFFF3E5F5),
            iconColor: Colors.purple,
          ),
          _buildCategoryCard(
            context,
            categoryId: '6b09ddff-ae2e-437c-850b-b552a8ea3a0b',
            title: "Visual dan Audio",
            subtitle: "Voice Over, edit video, podcast.",
            icon: Icons.music_note,
            bgColor: const Color(0xFFE0F2F1),
            iconColor: Colors.teal,
          ),
          _buildCategoryCard(
            context,
            categoryId: 'c85598f9-c7f1-4127-8a13-b509a08a65c0',
            title: "Penulisan & Penerjemahan",
            subtitle: "Olah kata konten, artikel, esai",
            icon: Icons.translate,
            bgColor: const Color(0xFFE8F5E9),
            iconColor: Colors.green,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String categoryId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceListPage(
              categoryId: categoryId,
              categoryName: title,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}