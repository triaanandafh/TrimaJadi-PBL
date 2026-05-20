import 'package:flutter/material.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Widget: VerifiedBadge
// Tampilkan badge "Verified" dengan ikon centang hijau.
// ──────────────────────────────────────────────────────────────────────────────
class VerifiedBadge extends StatelessWidget {
  final double fontSize;
  final double iconSize;

  const VerifiedBadge({
    super.key,
    this.fontSize = 11,
    this.iconSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00C853),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: iconSize),
          const SizedBox(width: 3),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget: StarRow
// Baris bintang dengan setengah-bintang sesuai nilai [rating].
// ──────────────────────────────────────────────────────────────────────────────
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  final Color  color;

  const StarRow({
    super.key,
    required this.rating,
    this.size  = 18,
    this.color = const Color(0xFFFFB800),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        late final IconData icon;
        if (star <= rating.floor()) {
          icon = Icons.star_rounded;
        } else if (star == rating.ceil() && rating % 1 >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: color, size: size);
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget: RatingChip
// Badge rating kecil (bintang + angka) untuk dipakai di kartu layanan.
// ──────────────────────────────────────────────────────────────────────────────
class RatingChip extends StatelessWidget {
  final double rating;
  final int    reviewCount;

  const RatingChip({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
        const SizedBox(width: 3),
        Text(
          rating > 0
              ? '${rating.toStringAsFixed(1)} ($reviewCount)'
              : 'Baru',
          style: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
      ],
    );
  }
}
