import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/rating_service.dart';

/// Halaman pengiriman ulasan oleh client setelah order selesai.
class ReviewPage extends StatefulWidget {
  final String orderId;
  final String talentId;
  final String talentName;
  final String serviceName;

  const ReviewPage({
    super.key,
    required this.orderId,
    required this.talentId,
    required this.talentName,
    required this.serviceName,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _supabase    = Supabase.instance.client;
  final _commentCtrl = TextEditingController();

  int  _rating      = 0;
  bool _isSubmitting = false;
  
  // Tambahan untuk mengecek apakah ulasan sudah pernah dibuat
  bool _isLoadingCheck = true; 
  bool _hasReviewed    = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  // Pengecekan Ulasan yang Sudah Ada
  Future<void> _checkExistingReview() async {
    try {
      final existingReview = await _supabase
          .from('reviews')
          .select('rating, comment')
          .eq('order_id', widget.orderId)
          .maybeSingle();

      if (existingReview != null && mounted) {
        setState(() {
          _hasReviewed = true;
          _rating = existingReview['rating'] ?? 0;
          _commentCtrl.text = existingReview['comment'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Gagal mengecek review: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCheck = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  // Submit review
  Future<void> _submitReview() async {
    if (_hasReviewed) return; // Keamanan tambahan jika statusnya sudah diulas
    
    if (_rating == 0) {
      _showSnackBar('Pilih bintang terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final clientId = _supabase.auth.currentUser?.id;
      if (clientId == null) throw Exception('Tidak terautentikasi');

      final checkDouble = await _supabase
          .from('reviews')
          .select('id')
          .eq('order_id', widget.orderId)
          .maybeSingle();
          
      if (checkDouble != null) {
        _showSnackBar('Kamu sudah memberikan ulasan untuk pesanan ini.', isError: true);
        setState(() {
          _hasReviewed = true;
          _isSubmitting = false;
        });
        return;
      }

      // 1. Simpan review
      await _supabase.from('reviews').insert({
        'order_id' : widget.orderId,
        'talent_id': widget.talentId,
        'client_id': clientId,
        'rating'   : _rating,
        'comment'  : _commentCtrl.text.trim(),
      });

      // 2. Tandai order sudah di-review
      await _supabase
          .from('orders')
          .update({'is_reviewed': true}).eq('id', widget.orderId);

      // 3. Periksa & beri Verified Badge (delegasi ke RatingService)
      await RatingService.checkAndGrantBadge(widget.talentId);

      if (mounted) {
        _showSnackBar('Ulasan berhasil dikirim! Terima kasih');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Gagal mengirim ulasan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red[400] : const Color(0xFF2C4A6E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:  return 'Sangat Buruk';
      case 2:  return 'Kurang Memuaskan';
      case 3:  return 'Cukup';
      case 4:  return 'Bagus';
      case 5:  return 'Luar Biasa!';
      default: return 'Tap bintang untuk memberi nilai';
    }
  }

  // Build
  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen saat sedang mengecek ke database
    if (_isLoadingCheck) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F2EF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      appBar: AppBar(
        title: const Text('Beri Ulasan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Banner Info Jika Sudah Diulas
            if (_hasReviewed)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Anda sudah memberikan ulasan untuk pesanan ini.',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Info Talent
            _WhiteCard(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.person, size: 36,
                        color: Color(0xFF3F51B5)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.talentName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF213E60)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.serviceName,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pilih Rating Bintang 
            _WhiteCard(
              child: Column(
                children: [
                  const Text(
                    'Bagaimana hasil pekerjaannya?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF213E60)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        // Nonaktifkan tap jika sudah pernah direview
                        onTap: _hasReviewed ? null : () => setState(() => _rating = star),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            star <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 44,
                            color: star <= _rating
                                ? const Color(0xFFFFB800)
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _ratingLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: _rating > 0
                          ? const Color(0xFFFFB800)
                          : Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Komentar 
            _WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komentar (opsional)',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF213E60)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 4,
                    maxLength: 300,
                    readOnly: _hasReviewed, // Buat Read-Only jika sudah di-review
                    decoration: InputDecoration(
                      hintText: _hasReviewed 
                          ? 'Tidak ada komentar' 
                          : 'Ceritakan pengalamanmu dengan talent ini...',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1E3A8A), width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Tombol Kirim / Kembali 
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasReviewed ? Colors.white : const Color(0xFF1E3A8A),
                  side: _hasReviewed ? const BorderSide(color: Color(0xFF1E3A8A)) : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                // Ubah fungsi tombol jika sudah di-review menjadi "Kembali"
                onPressed: _hasReviewed 
                    ? () => Navigator.pop(context) 
                    : (_isSubmitting ? null : _submitReview),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _hasReviewed ? 'Kembali' : 'Kirim Ulasan',
                        style: TextStyle(
                            color: _hasReviewed ? const Color(0xFF1E3A8A) : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Helper widget – kartu putih dengan shadow
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
