import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TalentProfilePreviewPage extends StatefulWidget {
  final String talentId;
  final String talentName;

  const TalentProfilePreviewPage({
    super.key,
    required this.talentId,
    required this.talentName,
  });

  @override
  State<TalentProfilePreviewPage> createState() => _TalentProfilePreviewPageState();
}

class _TalentProfilePreviewPageState extends State<TalentProfilePreviewPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _portfolios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      debugPrint('=== LOAD PROFIL ===');
      debugPrint('talentId: ${widget.talentId}');

      final profile = await supabase
          .from('users')
          .select('id, name, avatar_url, has_verified_badge')
          .eq('id', widget.talentId)
          .single();

      debugPrint('profile result: $profile');

      final reviews = await supabase
          .from('reviews')
          .select('rating')
          .eq('talent_id', widget.talentId);

      debugPrint('reviews result: $reviews');

      double avgRating = 0;
      int reviewCount = 0;
      if (reviews.isNotEmpty) {
        reviewCount = reviews.length;
        avgRating = reviews
                .map((r) => (r['rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            reviewCount;
      }

      final portfolios = await supabase
          .from('portfolios')
          .select('id, title, image_url, description')
          .eq('talent_id', widget.talentId)
          .limit(6);

      debugPrint('portfolios result: $portfolios');

      setState(() {
        _profile = {
          ...profile,
          'average_rating': avgRating,
          'review_count': reviewCount,
        };
        _portfolios = List<Map<String, dynamic>>.from(portfolios);
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR LOAD PROFIL: $e');
      debugPrint('STACK TRACE: $stackTrace');
      setState(() => _loading = false);
    }
  }

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (rating >= i + 1) {
          return const Icon(Icons.star, color: Color(0xFFFFC107), size: 16);
        } else if (rating >= i + 0.5) {
          return const Icon(Icons.star_half, color: Color(0xFFFFC107), size: 16);
        } else {
          return const Icon(Icons.star_border, color: Color(0xFFFFC107), size: 16);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil Talent',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profil tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- AVATAR + INFO ---
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFF3B5998),
                            backgroundImage: (_profile!['avatar_url'] != null &&
                                    (_profile!['avatar_url'] as String).isNotEmpty)
                                ? NetworkImage(_profile!['avatar_url'])
                                : null,
                            child: (_profile!['avatar_url'] == null ||
                                    (_profile!['avatar_url'] as String).isEmpty)
                                ? Text(
                                    getInitials(_profile!['name'] ?? widget.talentName),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          // Nama + verified + rating
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama + Verified Badge
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _profile!['name'] ?? widget.talentName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_profile!['has_verified_badge'] == true) ...[
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message: 'Talent Terverifikasi',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified,
                                                  color: Color(0xFF2E7D32), size: 13),
                                              SizedBox(width: 3),
                                              Text(
                                                'Verified',
                                                style: TextStyle(
                                                  color: Color(0xFF2E7D32),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Bintang rating
                                Row(
                                  children: [
                                    _buildStars(
                                        (_profile!['average_rating'] ?? 0).toDouble()),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${((_profile!['average_rating'] ?? 0) as num).toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${_profile!['review_count'] ?? 0} ulasan)',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // --- PORTOFOLIO ---
                      const Text(
                        'Portofolio',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),

                      _portfolios.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              child: Text(
                                'Belum ada portofolio.',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 13),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                              itemCount: _portfolios.length,
                              itemBuilder: (context, index) {
                                final item = _portfolios[index];
                                return GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (_) => DraggableScrollableSheet(
                                        initialChildSize: 0.6,
                                        minChildSize: 0.4,
                                        maxChildSize: 0.92,
                                        expand: false,
                                        builder: (_, scrollController) => SingleChildScrollView(
                                          controller: scrollController,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Handle bar
                                              Center(
                                                child: Container(
                                                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                                                  width: 40,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade300,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                              // Gambar full
                                              if (item['image_url'] != null)
                                                Image.network(
                                                  item['image_url'],
                                                  width: double.infinity,
                                                  height: 220,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    height: 220,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                                  ),
                                                ),
                                              // Judul & deskripsi
                                              Padding(
                                                padding: const EdgeInsets.all(20),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['title'] ?? '',
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    if (item['year'] != null) ...[
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Tahun: ${item['year']}',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey.shade500,
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      item['description'] ?? 'Tidak ada deskripsi.',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        item['image_url'] != null
                                            ? Image.network(
                                                item['image_url'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(color: Colors.grey.shade200),
                                              )
                                            : Container(color: Colors.grey.shade200),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.6),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              item['title'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}