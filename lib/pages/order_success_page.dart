import 'package:flutter/material.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final int totalPrice;
  final String serviceName;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.totalPrice,
    required this.serviceName,
  });

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              // ── 1. ILUSTRASI UTAMA (Meniru Gaya MyXL) ──
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.card_giftcard_rounded, // Bisa diganti aset gambar cewe megang kado jika ada
                    size: 72,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── 2. JUDUL STATUS RECONCILIATION ──
              const Text(
                'Pesanan Berhasil Dibuat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Harap tunggu! Pesananmu telah berhasil didaftarkan. Kamu bisa meninjau status pengerjaan secara berkala.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── 3. KARTU RINCIAN TRANSAKSI (SINKRON DENGAN KAMU MOCKUP) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildRowDetail('Layanan', serviceName),
                    const Divider(height: 24, thickness: 0.8),
                    _buildRowDetail('ID Transaksi', '#${orderId.substring(0, 8).toUpperCase()}'),
                    const Divider(height: 24, thickness: 0.8),
                    _buildRowDetail('Metode Pembayaran', 'Transfer Virtual Account'),
                    const Divider(height: 24, thickness: 0.8),
                    _buildRowDetail(
                      'Total Pembayaran', 
                      _formatRupiah(totalPrice),
                      isBoldValue: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── 4. TOMBOL UTAMA KEMBALI KE DASHBOARD ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E), // Warna Biru Navy TrimaJadi
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24), // Melengkung penuh khas MyXL
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Bersihkan seluruh tumpukan halaman dan kembali ke Dashboard Utama
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Kembali ke Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              color: isBoldValue ? const Color(0xFF1A237E) : Colors.black87,
            ),
            // textAlign: Alignment.centerRight,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}