import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'create_order_page.dart';
import '../services/rating_service.dart';
import '../widgets/rating_widgets.dart';

/// Halaman detail layanan dengan paket Basic / Standard / Premium
/// dan rating talent yang diambil dari database.
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

  @override
  void initState() {
    super.initState();
    _fetchRating();
  }

  Future<void> _fetchRating() async {
    final talentId = widget.service['talent_id']?.toString()
        ?? widget.service['users']?['id']?.toString();
    if (talentId == null) return;

    final summary = await RatingService.getSummary(talentId);
    if (mounted) setState(() => _ratingSummary = summary);
  }

  Map<String, dynamic>? _getPackage(String type) {
    final packages =
        widget.service['service_packages'] as List<dynamic>? ?? [];
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

  @override
  Widget build(BuildContext context) {
    final talentName   = widget.service['users']?['name'] ?? 'Talent';
    final avatarUrl    = widget.service['users']?['avatar_url'];
    final isVerified   = widget.service['users']?['is_verified'] == true
        || (_ratingSummary?.isVerified ?? false);
    final title        = widget.service['title'] ?? '';
    final imageUrl     = widget.service['image_url'];
    final selectedType = _tabs[_selectedTab].toLowerCase();
    final pkg          = _getPackage(selectedType);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── UBAHAN UTAMA 1: CONTAINER GRADASI LENGKUNG SEPERTI HOMEPAGE & LIST PAGE ──
          Container(
            height: 90, // Tinggi proposional untuk area detail tanpa search bar melayang
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), // Deep Blue (Profil kamu)
              Color(0xFF283593), // Indigo yang lebih terang
              Color(0xFF3949AB), // Light Indigo (Orderan kamu)
            ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),  // Lengkungan kiri bawah
                bottomRight: Radius.circular(30), // Lengkungan kanan bawah
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20), // Padding 20 biar lurus vertikal
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tombol Back Semi Transparan Bulat
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: const CircleBorder(),
                      ),
                    ),
                    
                    // Judul Layanan di Tengah Header
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
                    
                    // Spasi dummy 48px agar posisi judul presisi di tengah (seimbang dengan tombol back)
                    const SizedBox(width: 48), 
                  ],
                ),
              ),
            ),
          ),

          // ── UBAHAN UTAMA 2: AREA KONTEN SEKARANG DIBAWAH HEADER MENGGUNAKAN PADDING TOP ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 90), // Memberikan jarak agar konten tidak menabrak kelengkungan header biru

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Info Talent ──────────────────────────────────
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl as String)
                                  : null,
                              child: avatarUrl == null
                                  ? const Icon(Icons.person, color: Colors.grey)
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
                                      reviewCount: _ratingSummary!.reviewCount,
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

                  // ── Gambar Layanan ───────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl as String,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
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

                  // ── Tab Basic / Standard / Premium ───────────────
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final isSelected = _selectedTab == i;
                        final available  = _getPackage(
                                _tabs[i].toLowerCase())?['price'] !=
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

                  // ── Konten Paket ─────────────────────────────────
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
                                              color: Color(0xFF1A43BF),
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(line,
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                          ),
                                        ],
                                      ),
                                    )),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // ── Tombol Lanjutkan ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: SizedBox(
              width: double.infinity,
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
                            builder: (_) =>
                                CreateOrderPage(serviceId: serviceId),
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
                      fontSize: 16,
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
    );
  }
}
