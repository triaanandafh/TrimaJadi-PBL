import 'package:flutter/material.dart';
import '../widgets/rating_widgets.dart';

/// Kartu layanan untuk ditampilkan di grid/list pencarian.
/// Parameter [onTap] diarahkan ke ServiceDetailPage.
class ServiceCard extends StatelessWidget {
  final Map<String, dynamic>? service;
  final VoidCallback?          onTap;

  const ServiceCard({super.key, this.service, this.onTap});

  String _formatPrice(dynamic price) {
    if (price == null) return '-';
    final p = (price as num).toDouble();
    return 'IDR ${p.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final title      = service?['title']?.toString() ?? 'Layanan';
    final talentName = service?['users']?['name']?.toString() ?? '';
    final imageUrl   = service?['image_url']?.toString();
    final isVerified = service?['users']?['is_verified'] == true;
    final avgRating  = (service?['avg_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCnt  = (service?['review_count'] as num?)?.toInt() ?? 0;

    // Harga minimum dari paket yang tersedia
    final packages = (service?['service_packages'] as List<dynamic>?) ?? [];
    final prices = packages
        .map((p) => (p['price'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final minPrice = prices.isEmpty ? null : (prices..sort()).first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
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

            // ── Gambar ──────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Nama Talent + Badge ──────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          talentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(fontSize: 9, iconSize: 10),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // ── Judul Layanan ────────────────────────────────
                  Text(
                    title,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // ── Rating ───────────────────────────────────────
                  RatingChip(
                      rating: avgRating, reviewCount: reviewCnt),

                  const SizedBox(height: 6),

                  // ── Harga ────────────────────────────────────────
                  Text(
                    minPrice != null
                        ? 'Mulai dari ${_formatPrice(minPrice)}'
                        : 'Hubungi untuk harga',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 130,
        width: double.infinity,
        color: const Color(0xFFE8F0FF),
        child: const Icon(Icons.image, size: 40, color: Color(0xFF1A43BF)),
      );
}
