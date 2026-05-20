import 'package:supabase_flutter/supabase_flutter.dart';

/// Layanan terpusat untuk perhitungan rating dan pemberian Verified Badge.
///
/// Syarat Verified Badge:
///   • Minimal 7 ulasan yang masuk
///   • Rata-rata rating ≥ 4.5
class RatingService {
  static final _supabase = Supabase.instance.client;

  /// Ambil statistik rating talent.
  /// Mengembalikan [RatingSummary] berisi jumlah ulasan, rata-rata, dan status verified.
  static Future<RatingSummary> getSummary(String talentId) async {
    final reviews = await _supabase
        .from('reviews')
        .select('rating')
        .eq('talent_id', talentId);

    final list = List<Map<String, dynamic>>.from(reviews);
    final count = list.length;
    final avg = count == 0
        ? 0.0
        : list.fold<double>(
                0, (sum, r) => sum + (r['rating'] as num).toDouble()) /
            count;

    final profile = await _supabase
        .from('users')
        .select('is_verified')
        .eq('id', talentId)
        .maybeSingle();

    return RatingSummary(
      reviewCount: count,
      averageRating: avg,
      isVerified: profile?['is_verified'] == true,
    );
  }

  /// Periksa apakah talent layak mendapat Verified Badge dan berikan jika memenuhi syarat.
  /// Dipanggil otomatis setiap kali review baru dikirim.
  static Future<void> checkAndGrantBadge(String talentId) async {
    try {
      final summary = await getSummary(talentId);

      // Sudah verified → tidak perlu cek ulang
      if (summary.isVerified) return;

      if (summary.reviewCount >= 7 && summary.averageRating >= 4.5) {
        await _supabase
            .from('users')
            .update({'is_verified': true}).eq('id', talentId);
      }
    } catch (_) {
      // Badge check gagal tidak menghentikan flow utama
    }
  }
}

/// Data ringkasan rating talent.
class RatingSummary {
  final int    reviewCount;
  final double averageRating;
  final bool   isVerified;

  const RatingSummary({
    required this.reviewCount,
    required this.averageRating,
    required this.isVerified,
  });

  /// Apakah syarat verified sudah terpenuhi (terlepas dari status DB).
  bool get meetsVerifiedCriteria =>
      reviewCount >= 7 && averageRating >= 4.5;

  /// Progres jumlah ulasan menuju 7 (0.0 – 1.0).
  double get reviewProgress => (reviewCount / 7).clamp(0.0, 1.0);
}
