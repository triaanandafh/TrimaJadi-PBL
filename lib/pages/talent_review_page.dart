import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TalentReviewsPage extends StatefulWidget {
  /// Jika null, ambil talent dari current user (untuk halaman profil talent sendiri)
  final String? talentId;
  final String? talentName;

  const TalentReviewsPage({super.key, this.talentId, this.talentName});

  @override
  State<TalentReviewsPage> createState() => _TalentReviewsPageState();
}

class _TalentReviewsPageState extends State<TalentReviewsPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _avgRating = 0;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  String get _talentId =>
      widget.talentId ?? supabase.auth.currentUser?.id ?? '';

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      // Ambil reviews
      final res = await supabase
          .from('reviews')
          .select()
          .eq('talent_id', _talentId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);

      // Hitung rata-rata
      double avg = 0;
      if (list.isNotEmpty) {
        avg = list.fold<double>(
                0, (sum, r) => sum + ((r['rating'] as num).toDouble())) /
            list.length;
      }

      // Cek verified badge
      final profile = await supabase
          .from('users')
          .select('is_verified')
          .eq('id', _talentId)
          .maybeSingle();

      setState(() {
        _reviews    = list;
        _avgRating  = avg;
        _isVerified = profile?['is_verified'] == true;
        _isLoading  = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt  = DateTime.parse(iso).toLocal();
      final mon = ['Jan','Feb','Mar','Apr','Mei','Jun',
                   'Jul','Agt','Sep','Okt','Nov','Des'];
      return '${dt.day} ${mon[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      appBar: AppBar(
        title: Text(
          widget.talentName != null
              ? 'Ulasan untuk ${widget.talentName}'
              : 'Ulasan Klien',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReviews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReviews,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Kartu Ringkasan Rating ──
                    _buildSummaryCard(),
                    const SizedBox(height: 20),

                    // ── Syarat Verified Badge ──
                    _buildVerifiedInfo(),
                    const SizedBox(height: 20),

                    // ── List Ulasan ──
                    if (_reviews.isEmpty)
                      _buildEmpty()
                    else
                      ...(_reviews.map((r) => _buildReviewCard(r)).toList()),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Rating Talent',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (_isVerified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 13),
                            SizedBox(width: 3),
                            Text('Verified',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6, left: 4),
                      child: Text('/5.0',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildStarRow(_avgRating, size: 20),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.reviews_outlined,
                  color: Colors.white24, size: 48),
              const SizedBox(height: 8),
              Text(
                '${_reviews.length} ulasan',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedInfo() {
    final reviewCount = _reviews.length;
    final progress = (reviewCount / 7).clamp(0.0, 1.0);
    final avgOk    = _avgRating >= 4.5;
    final countOk  = reviewCount >= 7;

    if (_isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF00C853).withOpacity(0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF00C853), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Talent Terverifikasi!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                          fontSize: 14)),
                  SizedBox(height: 2),
                  Text(
                    'Kamu telah mendapatkan Verified Badge atas kualitas kerja yang luar biasa.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Syarat Verified Badge',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          // Syarat 1: Jumlah order
          Row(
            children: [
              Icon(
                countOk ? Icons.check_circle : Icons.radio_button_unchecked,
                color: countOk ? Colors.green : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Minimal 7 ulasan ($reviewCount/7)',
                style: TextStyle(
                    fontSize: 13,
                    color: countOk ? Colors.green[700] : Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  countOk ? Colors.green : Colors.orange),
            ),
          ),
          const SizedBox(height: 10),

          // Syarat 2: Rata-rata bintang
          Row(
            children: [
              Icon(
                avgOk ? Icons.check_circle : Icons.radio_button_unchecked,
                color: avgOk ? Colors.green : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Rata-rata ≥ 4.5 bintang (${_avgRating > 0 ? _avgRating.toStringAsFixed(1) : "-"})',
                style: TextStyle(
                    fontSize: 13,
                    color: avgOk ? Colors.green[700] : Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.star_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Belum ada ulasan',
              style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          const SizedBox(height: 4),
          Text('Ulasan akan muncul setelah order selesai',
              style: TextStyle(color: Colors.grey[350], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating  = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment']?.toString() ?? '';
    final date    = _formatDate(review['created_at']?.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.person, color: Color(0xFF3F51B5), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Klien',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF213E60))),
                      Text(date,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                ],
              ),
              _buildStarRow(rating.toDouble(), size: 16),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        IconData icon;
        if (star <= rating.floor()) {
          icon = Icons.star_rounded;
        } else if (star == rating.ceil() && rating % 1 >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: const Color(0xFFFFB800), size: size);
      }),
    );
  }
}
