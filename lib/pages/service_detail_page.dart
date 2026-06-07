import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_order_page.dart';
import '../services/rating_service.dart';
import '../widgets/rating_widgets.dart';
import 'chat_page.dart';

/// Halaman detail layanan dengan paket Basic / Standard / Premium,
/// portofolio talent, dan detail rating dari database.
class ServiceDetailPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  int _selectedTab = 0;
  final _tabs = const ['Basic', 'Standard', 'Premium'];

  RatingSummary? _ratingSummary;
  List<Map<String, dynamic>> _portfolios = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingPortfolio = true;
  bool _loadingReviews = true;

  String? get _talentId =>
      widget.service['user_id']?.toString() ??
      widget.service['users']?['id']?.toString();

  @override
  void initState() {
    super.initState();
    _fetchRating();
    _fetchPortfolios();
    _fetchReviews();
  }

  Future<void> _fetchRating() async {
    final talentId = _talentId;
    if (talentId == null) return;
    final summary = await RatingService.getSummary(talentId);
    if (mounted) setState(() => _ratingSummary = summary);
  }

  Future<void> _fetchPortfolios() async {
    final talentId = _talentId;
    if (talentId == null) {
      if (mounted) setState(() => _loadingPortfolio = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('portfolios')
          .select('id, title, description, year, image_url')
          .eq('talent_id', talentId)
          .order('created_at', ascending: false)
          .limit(6);
      if (mounted) {
        setState(() {
          _portfolios = List<Map<String, dynamic>>.from(data as List);
          _loadingPortfolio = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching portfolios: $e');
      if (mounted) setState(() => _loadingPortfolio = false);
    }
  }

  Future<void> _fetchReviews() async {
    final talentId = _talentId;
    if (talentId == null) {
      if (mounted) setState(() => _loadingReviews = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('reviews')
          .select('rating, comment, created_at, users:client_id(name, avatar_url)')
          .eq('talent_id', talentId)
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(data as List);
          _loadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Map<String, dynamic>? _getPackage(String type) {
    final packages = widget.service['service_packages'] as List<dynamic>? ?? [];
    try {
      return packages.firstWhere((p) => p['package_type'] == type)
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Tidak tersedia';
    final p = (price as num).toDouble();
    return 'IDR ${p.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} bln lalu';
    if (diff.inDays >= 1) return '${diff.inDays} hari lalu';
    if (diff.inHours >= 1) return '${diff.inHours} jam lalu';
    return 'Baru saja';
  }

  Widget _buildStars(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded,
              color: const Color(0xFFFFC107), size: size);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded,
              color: const Color(0xFFFFC107), size: size);
        }
        return Icon(Icons.star_outline_rounded,
            color: Colors.grey[300], size: size);
      }),
    );
  }

  Widget _buildRatingBar(int starLevel, int count, int total) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text('$starLevel',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF1A43BF),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text('$count',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1A237E)),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // PORTOFOLIO
  // ══════════════════════════════════════════════════════════
  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Portofolio', icon: Icons.photo_library_outlined),
        const SizedBox(height: 14),
        if (_loadingPortfolio)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1A237E),
              ),
            ),
          )
        else if (_portfolios.isEmpty)
          _emptyState(Icons.image_not_supported_outlined, 'Belum ada portofolio')
        else
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _portfolios.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _portfolios[index];
                final imgUrl = item['image_url'] as String?;
                final itemTitle = item['title'] as String? ?? '';
                final year = item['year']?.toString() ?? '';

                return GestureDetector(
                  onTap: () => _showPortfolioDetail(item),
                  child: Container(
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDDE3FF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: imgUrl != null && imgUrl.isNotEmpty
                              ? Image.network(
                                  imgUrl,
                                  height: 130,
                                  width: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _portfolioImagePlaceholder(height: 130, width: 180),
                                )
                              : _portfolioImagePlaceholder(height: 130, width: 180),
                        ),
                        // Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        itemTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF1A237E),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (year.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8EEFF),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          year,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 10, color: Color(0xFF1A43BF)),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Lihat detail',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF1A43BF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _portfolioImagePlaceholder({double height = 180, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: const Color(0xFFE8F0FF),
      child: const Icon(Icons.image_outlined,
          size: 40, color: Color(0xFF1A43BF)),
    );
  }

  void _showPortfolioDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final imgUrl = item['image_url'] as String?;
        final title = item['title'] as String? ?? '';
        final desc = item['description'] as String? ?? '';
        final year = item['year']?.toString() ?? '';
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (_, controller) => ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (imgUrl != null && imgUrl.isNotEmpty)
                Image.network(imgUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _portfolioImagePlaceholder()),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (year.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(year,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E))),
                          ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  // RATING & ULASAN
  // ══════════════════════════════════════════════════════════
  Widget _buildRatingSection() {
    final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _reviews) {
      final star = ((r['rating'] as num?)?.round() ?? 0).clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    final total = _reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Ulasan Klien', icon: Icons.reviews_outlined),
        const SizedBox(height: 14),

        // Ringkasan rating
        if (_ratingSummary != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0F3FF), Color(0xFFE8EEFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE3FF)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _ratingSummary!.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStars(_ratingSummary!.averageRating, size: 18),
                    const SizedBox(height: 6),
                    Text(
                      '${_ratingSummary!.reviewCount} ulasan',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1]
                        .map((s) => _buildRatingBar(s, dist[s] ?? 0, total))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Daftar ulasan
        if (_loadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF1A237E),
              ),
            ),
          )
        else if (_reviews.isEmpty)
          _emptyState(Icons.rate_review_outlined, 'Belum ada ulasan')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.grey.shade100, height: 28, thickness: 1),
            itemBuilder: (context, index) {
              final rev = _reviews[index];
              final reviewer = rev['users'] as Map<String, dynamic>? ?? {};
              final reviewerName = reviewer['name'] as String? ?? 'Anonim';
              final reviewerAvatar = reviewer['avatar_url'] as String?;
              final rating = (rev['rating'] as num?)?.toDouble() ?? 0;
              final comment = rev['comment'] as String? ?? '';
              final createdAt = rev['created_at'] as String?;
              final isEmpty = comment.isEmpty || comment == 'EMPTY';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE8EEFF),
                    backgroundImage: reviewerAvatar != null
                        ? NetworkImage(reviewerAvatar)
                        : null,
                    child: reviewerAvatar == null
                        ? Text(
                            reviewerName.isNotEmpty
                                ? reviewerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reviewerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              _timeAgo(createdAt),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _buildStars(rating, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                        if (!isEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE8EEFF)),
                            ),
                            child: Text(
                              comment,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tidak memberikan komentar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: Colors.grey[350]),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final talentName = widget.service['users']?['name'] ?? 'Talent';
    final avatarUrl = widget.service['users']?['avatar_url'];
    final isVerified = _ratingSummary?.hasVerifiedBadge ?? false;
    final title = widget.service['title'] ?? '';
    final imageUrl = widget.service['image_url'];
    final selectedType = _tabs[_selectedTab].toLowerCase();
    final pkg = _getPackage(selectedType);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header gradasi
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: const CircleBorder(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Konten utama
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 90),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Info Talent
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl as String)
                                  : null,
                              child: avatarUrl == null
                                  ? const Icon(Icons.person,
                                      color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(talentName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      if (isVerified) ...[
                                        const SizedBox(width: 6),
                                        const VerifiedBadge(
                                            fontSize: 10, iconSize: 11),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  if (_ratingSummary != null)
                                    RatingChip(
                                      rating: _ratingSummary!.averageRating,
                                      reviewCount:
                                          _ratingSummary!.reviewCount,
                                    )
                                  else
                                    const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Gambar Layanan
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl as String,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: const Color(0xFFE8F0FF),
                                    child: const Icon(Icons.image,
                                        size: 60,
                                        color: Color(0xFF1A43BF)),
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: const Color(0xFFE8F0FF),
                                  child: const Icon(Icons.image,
                                      size: 60, color: Color(0xFF1A43BF)),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // Tab Basic / Standard / Premium
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: List.generate(_tabs.length, (i) {
                              final isSelected = _selectedTab == i;
                              final available =
                                  _getPackage(_tabs[i].toLowerCase())?[
                                          'price'] !=
                                      null;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: available
                                      ? () =>
                                          setState(() => _selectedTab = i)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF1A43BF)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _tabs[i],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF1A43BF)
                                            : available
                                                ? Colors.black
                                                : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Konten Paket
                        if (pkg == null || pkg['price'] == null)
                          Center(
                            child: Text(
                              'Paket ${_tabs[_selectedTab]} tidak tersedia',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatPrice(pkg['price']),
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A43BF)),
                              ),
                              const SizedBox(height: 15),
                              if (pkg['package_description'] != null)
                                ...(pkg['package_description'] as String)
                                    .split('\n')
                                    .map((line) => line.trim().isEmpty
                                        ? const SizedBox(height: 4)
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.check,
                                                    color:
                                                        Color(0xFF1A43BF),
                                                    size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(line,
                                                      style:
                                                          const TextStyle(
                                                              fontSize:
                                                                  14)),
                                                ),
                                              ],
                                            ),
                                          )),
                            ],
                          ),

                        // PORTOFOLIO
                        const SizedBox(height: 32),
                        _buildPortfolioSection(),

                        // RATING & ULASAN
                        const SizedBox(height: 32),
                        _buildRatingSection(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Tombol Chat + Lanjutkan
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final talentId =
                                  widget.service['talent_id']?.toString() ??
                                      widget.service['user_id']?.toString() ??
                                      '';
                              final tName =
                                  widget.service['users']?['name'] ?? 'Talent';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                      name: tName, receiverId: talentId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 18, color: Color(0xFF1A237E)),
                            label: const Text(
                              'Chat Talent',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFF1A237E), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: pkg == null || pkg['price'] == null
                                ? null
                                : () {
                                    final serviceId =
                                        widget.service['id']?.toString() ?? '';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CreateOrderPage(
                                            serviceId: serviceId),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text(
                              'Lanjutkan',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
