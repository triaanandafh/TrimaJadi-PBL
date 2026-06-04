import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'service_list_page.dart';
import 'service_detail_page.dart';
import 'search_service_page.dart';

class HomepageClient extends StatefulWidget {
  final VoidCallback onTapSearch;
  final VoidCallback onViewAll; 

  const HomepageClient({super.key, required this.onTapSearch, required this.onViewAll,});

  @override
  State<HomepageClient> createState() => _HomepageClientState();
}

class _HomepageClientState extends State<HomepageClient> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _popularCategories = [];
  List<Map<String, dynamic>> _popularServices = [];
  bool _isLoading = true;

  // Mapping kategori name → icon & warna
  final Map<String, Map<String, dynamic>> _categoryStyle = {
    'Desain': {
      'icon': Icons.palette,
      'bgColor': const Color(0xFFE3F2FD),
      'iconColor': Colors.blue,
      'id': '34b4a9b2-2b77-4ce3-afc9-7a119212d6b3',
    },
    'Web & Pemrograman': {
      'icon': Icons.code,
      'bgColor': const Color(0xFFFFF3E0),
      'iconColor': Color(0xFFE68C3A),
      'id': '631f54e5-5a7f-4626-8d11-e8a75efc1ac7',
    },
    'Edukasi': {
      'icon': Icons.school,
      'bgColor': const Color(0xFFF3E5F5),
      'iconColor': Colors.purple,
      'id': 'ae281474-8aec-4ae5-94d8-edbaba273e6d',
    },
    'Visual dan Audio': {
      'icon': Icons.music_note,
      'bgColor': const Color(0xFFE0F2F1),
      'iconColor': Colors.teal,
      'id': '6b09ddff-ae2e-437c-850b-b552a8ea3a0b',
    },
    'Penulisan & Penerjemahan': {
      'icon': Icons.translate,
      'bgColor': const Color(0xFFE8F5E9),
      'iconColor': Colors.green,
      'id': 'c85598f9-c7f1-4127-8a13-b509a08a65c0',
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchPopularCategories(),
        _fetchPopularServices(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPopularCategories() async {
    try {
      // Hitung order per kategori lewat services
      final response = await _supabase
          .from('categories')
          .select('''
            id, name,
            services(
              orders(id)
            )
          ''');

      final categories = List<Map<String, dynamic>>.from(response);

      // Hitung total order per kategori
      final withCount = categories.map((cat) {
        final services = cat['services'] as List<dynamic>? ?? [];
        int totalOrders = 0;
        for (final service in services) {
          final orders = service['orders'] as List<dynamic>? ?? [];
          totalOrders += orders.length;
        }
        return {...cat, 'order_count': totalOrders};
      }).toList();

      // Urutkan dari terbanyak
      withCount.sort((a, b) =>
          (b['order_count'] as int).compareTo(a['order_count'] as int));

      setState(() => _popularCategories = withCount);
    } catch (_) {}
  }

  Future<void> _fetchPopularServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select('''
            id, title, image_url, description,
            orders(id),
            users(id, name, avatar_url, is_verified),
            categories(name),
            service_packages(package_type, price, package_description)
          '''); // ← tambah relasi yang dibutuhkan ServiceDetailPage

      final services = List<Map<String, dynamic>>.from(response);

      final withCount = services.map((s) {
        final orders = s['orders'] as List<dynamic>? ?? [];
        return {...s, 'order_count': orders.length};
      }).toList();

      withCount.sort((a, b) =>
          (b['order_count'] as int).compareTo(a['order_count'] as int));

      setState(() => _popularServices = withCount.take(10).toList());
    } catch (_) {}
  }

  String _shortLabel(String name) {
    if (name == 'Web & Pemrograman') return 'Web & Pemr\nograman';
    if (name == 'Penulisan & Penerjemahan') return 'Penulisan';
    if (name == 'Visual dan Audio') return 'Visual &\nAudio';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header & Search Bar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 125,
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
                        padding: const EdgeInsets.only(
                            left: 25, right: 25, top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white24,
                                  backgroundImage:
                                      UserData.avatarUrl.isNotEmpty
                                          ? NetworkImage(UserData.avatarUrl)
                                          : null,
                                  child: UserData.avatarUrl.isEmpty
                                      ? const Icon(Icons.person,
                                          color: Colors.white, size: 24)
                                      : null,
                                ),
                                const SizedBox(width: 12),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none,
                                  color: Color(0xFFE68C3A), size: 26),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Search Bar
                  Positioned(
                    bottom: -25,
                    left: 25,
                    right: 25,
                    child: GestureDetector(
                      onTap: widget.onTapSearch,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 10),
                              Text("Cari layanan...",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori Populer
                    _buildSectionTitle(
                      "Kategori Populer",
                      onTap: widget.onViewAll,
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _popularCategories.map((cat) {
                                final name = cat['name']?.toString() ?? '';
                                final style = _categoryStyle[name] ?? {
                                  'icon': Icons.category,
                                  'bgColor': const Color(0xFFE3F2FD),
                                  'iconColor': Colors.blue,
                                  'id': cat['id'],
                                };
                                return _buildCategoryItem(
                                  _shortLabel(name),
                                  style['icon'] as IconData,
                                  style['bgColor'] as Color,
                                  style['iconColor'] as Color,
                                  categoryId: cat['id']?.toString() ?? '',
                                  categoryName: name,
                                );
                              }).toList(),
                            ),
                          ),

                    const SizedBox(height: 35),

                    // Promo Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/image.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // Layanan Populer
                    _buildSectionTitle(
                      "Layanan Populer",
                      onTap: widget.onViewAll,
                    ),
                    const SizedBox(height: 15),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _popularServices.map((service) {
                                return _buildServiceCard(
                                  service['title']?.toString() ?? '',
                                  service['image_url']?.toString(),
                                  service,
                                );
                              }).toList(),
                            ),
                          ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF213E60)),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            "Lihat Semua",
            style: TextStyle(
                fontSize: 13,
                color: Color(0xFF94B6EF),
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    required String categoryId,
    required String categoryName,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceListPage(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          width: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 35,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    String title,
    String? imageUrl,
    Map<String, dynamic> service,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailPage(service: service),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 100,
                        color: const Color(0xFFE8F0FF),
                        child: const Icon(Icons.image,
                            color: Color(0xFF1A43BF)),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: const Color(0xFFE8F0FF),
                      child: const Icon(Icons.image,
                          color: Color(0xFF1A43BF)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}