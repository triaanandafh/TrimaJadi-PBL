import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/rating_service.dart';
import '../widgets/rating_widgets.dart';

/// Halaman daftar ulasan untuk satu talent.
/// Jika [talentId] null → tampilkan ulasan talent yang sedang login.
class TalentReviewsPage extends StatefulWidget {
  final String? talentId;
  final String? talentName;

  const TalentReviewsPage({super.key, this.talentId, this.talentName});

  @override
  State<TalentReviewsPage> createState() => _TalentReviewsPageState();
}

class _TalentReviewsPageState extends State<TalentReviewsPage> {
  final _supabase = Supabase.instance.client;

  bool   _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  RatingSummary? _summary;

  String get _talentId =>
      widget.talentId ?? _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('reviews')
          .select()
          .eq('talent_id', _talentId)
          .order('created_at', ascending: false);

      final summary = await RatingService.getSummary(_talentId);

      setState(() {
        _reviews   = List<Map<String, dynamic>>.from(res);
        _summary   = summary;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final title = widget.talentName != null
        ? 'Ulasan untuk ${widget.talentName}'
        : 'Ulasan Klien';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _fetchReviews),
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
                    if (_summary != null) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildVerifiedProgress(),
                      const SizedBox(height: 20),
                    ],
                    _reviews.isEmpty
                        ? _buildEmpty()
                        : Column(
                            children:
                                _reviews.map(_buildReviewCard).toList(),
                          ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Kartu ringkasan rating ───────────────────────────────────────────
  Widget _buildSummaryCard() {
    final s = _summary!;
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
                    const Text('Rating Talent',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    if (s.isVerified) ...[
                      const SizedBox(width: 8),
                      const VerifiedBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      s.averageRating.toStringAsFixed(1),
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
                StarRow(rating: s.averageRating, size: 20,
                    color: const Color(0xFFFFB800)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.reviews_outlined,
                  color: Colors.white24, size: 48),
              const SizedBox(height: 8),
              Text('${s.reviewCount} ulasan',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress menuju Verified Badge ─────────────────────────────────
  Widget _buildVerifiedProgress() {
    final s = _summary!;

    if (s.isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF00C853).withOpacity(0.4)),
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
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final countOk = s.reviewCount >= 7;
    final avgOk   = s.averageRating >= 4.5;

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
              Icon(Icons.verified_outlined,
                  color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Syarat Verified Badge',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),

          // Syarat 1: jumlah ulasan
          _criteriaRow(
            met: countOk,
            label: 'Minimal 7 ulasan (${s.reviewCount}/7)',
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: s.reviewProgress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  countOk ? Colors.green : Colors.orange),
            ),
          ),
          const SizedBox(height: 10),

          // Syarat 2: rata-rata bintang
          _criteriaRow(
            met: avgOk,
            label:
                'Rata-rata ≥ 4.5 bintang (${s.averageRating > 0 ? s.averageRating.toStringAsFixed(1) : '-'})',
          ),
        ],
      ),
    );
  }

  Widget _criteriaRow({required bool met, required String label}) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: met ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              color: met ? Colors.green[700] : Colors.grey[700]),
        ),
      ],
    );
  }

  // ── Kartu ulasan ────────────────────────────────────────────────────
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
                    child: Icon(Icons.person,
                        color: Color(0xFF3F51B5), size: 20),
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
              StarRow(rating: rating.toDouble(), size: 16),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[700], height: 1.5)),
          ],
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

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt  = DateTime.parse(iso).toLocal();
      const mon = [
        'Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agt','Sep','Okt','Nov','Des'
      ];
      return '${dt.day} ${mon[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
