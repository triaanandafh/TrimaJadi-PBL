import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trimajadi/pages/service_list_page.dart';
import 'package:trimajadi/pages/service_detail_page.dart';

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
      // Cari berdasarkan judul layanan
      final byTitle = await _supabase
          .from('services')
          .select('''
            id, title, description, image_url,
            categories(name),
            users(name, avatar_url),
            service_packages(package_type, price, package_description)
          ''')
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
              categories(name),
              users(name, avatar_url),
              service_packages(package_type, price, package_description)
            ''')
            .inFilter('user_id', talentIds);
        byTalent = List<Map<String, dynamic>>.from(byTalentResponse);
      }

      // Gabungkan hasil, hindari duplikat
      final Map<String, Map<String, dynamic>> combined = {};
      for (final s in [...byTitle, ...byTalent]) {
        combined[s['id']] = s;
      }

      setState(() {
        _searchResults = combined.values.toList();
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
      backgroundColor: const Color(0xFFF5F7FB), // Menggunakan latar abu muda sesuai mockup kanan
      body: Stack(
        children: [
          // 1. REVISI: HEADER BIRU GRADASI SEPERTI MOCKUP KANAN
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A237E), // Deep Blue
                  Color(0xFF283593), // Indigo
                  Color(0xFF3949AB), // Light Indigo
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                              "Cari Layanan",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Temukan jasa terbaik",
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                            ),
                          ],
                        ),
                        // Notifikasi dengan bulatan transparan ala mockup
                        IconButton(
                          icon: const Icon(Icons.notifications_none_outlined, size: 28, color: Colors.white),
                          onPressed: () {},
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. AREA UTAMA (Menggunakan ScrollView)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 130), // Spacer memberikan ruang untuk title di atas

                // Floating Search Bar & Filter Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
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
                            controller: _searchController,
                            onChanged: _search,
                            decoration: InputDecoration(
                              hintText: "Cari layanan...",
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: _isSearching
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        _search('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Filter Kotak Melayang Putih
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],  
                        ),
                        child: const Icon(Icons.tune, color: Color(0xFF1A237E), size: 26),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Area Konten Dinamis
                Expanded(
                  child: _isSearching
                      ? _buildSearchResults()
                      : _buildCategoryList(),
                ),
              ],
            ),
          ),
        ],
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
        final packages =
            service['service_packages'] as List<dynamic>? ?? [];
        final minPrice = _getMinPrice(packages);

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                    Text(categoryName, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(service['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(talentName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(minPrice, style: const TextStyle(color: Color(0xFFE68C3A), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoryName,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(service['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(talentName,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 6),
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
          ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header Kategori seperti di mockup kanan
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Kategori",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                ),
                Text(
                  "5 layanan",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // REVISI: Semua Card Kategori dirubah berlatar belakang putih bersih (Gaya Mockup Kanan)
          _buildCategoryCard(
            context,
            categoryId: '34b4a9b2-2b77-4ce3-afc9-7a119212d6b3',
            title: "Desain",
            subtitle: "Logo, seni, dan ilustrasi",
            icon: Icons.palette,
            iconBgColor: const Color(0xFFE3F2FD),
            iconColor: Colors.blue,
          ),
          _buildCategoryCard(
            context,
            categoryId: '631f54e5-5a7f-4626-8d11-e8a75efc1ac7',
            title: "Web & Pemrograman",
            subtitle: "Pengembangan Website",
            icon: Icons.code,
            iconBgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE68C3A),
          ),
          _buildCategoryCard(
            context,
            categoryId: 'ae281474-8aec-4ae5-94d8-edbaba273e6d',
            title: "Edukasi",
            subtitle: "Bimbingan belajar, mentoring",
            icon: Icons.school,
            iconBgColor: const Color(0xFFF3E5F5),
            iconColor: Colors.purple,
          ),
          _buildCategoryCard(
            context,
            categoryId: '6b09ddff-ae2e-437c-850b-b552a8ea3a0b',
            title: "Visual dan Audio",
            subtitle: "Voice Over, edit video, podcast.",
            icon: Icons.music_note,
            iconBgColor: const Color(0xFFE0F2F1),
            iconColor: Colors.teal,
          ),
          _buildCategoryCard(
            context,
            categoryId: 'c85598f9-c7f1-4127-8a13-b509a08a65c0',
            title: "Penulisan & Penerjemahan",
            subtitle: "Olah kata konten, artikel, esai",
            icon: Icons.translate,
            iconBgColor: const Color(0xFFE8F5E9),
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
    required Color iconBgColor, // Diubah menjadi latar khusus lingkaran ikon saja
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // REVISI: Semua berlatar putih bersih
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Lingkaran Ikon Berwarna Khusus
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }
}