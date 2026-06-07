import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trimajadi/pages/main_screen.dart';

// 1. MODEL & DATA METODE PEMBAYARAN
class PaymentMethodModel {
  final String id;
  final String name;
  final String shortName; 
  final bool isVirtualAccount;
  final Color color;
  final List<String> steps;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.isVirtualAccount,
    required this.color,
    required this.steps,
  });
}

final List<PaymentMethodModel> paymentOptions = [
  PaymentMethodModel(
    id: 'bca_va',
    name: 'Virtual Account BCA',
    shortName: 'BCA',
    isVirtualAccount: true,
    color: const Color(0xFF0070B8),
    steps: [
      'Salin nomor Virtual Account di atas.',
      'Buka aplikasi / mesin ATM BCA.',
      'Pilih menu Transfer > Virtual Account, masukkan nomor VA.',
      'Konfirmasi nominal pembayaran lalu bayar.',
      'Kembali ke sini dan tekan tombol "Konfirmasi Pembayaran".',
    ],
  ),
  PaymentMethodModel(
    id: 'mandiri_va',
    name: 'Virtual Account Mandiri',
    shortName: 'MDR',
    isVirtualAccount: true,
    color: const Color(0xFF003D79),
    steps: [
      'Salin nomor Virtual Account di atas.',
      'Buka aplikasi Livin\' by Mandiri / mesin ATM.',
      'Pilih menu Bayar > Multipayment, masukkan nomor VA.',
      'Konfirmasi nominal dan selesaikan pembayaran.',
      'Kembali ke sini untuk konfirmasi manual.',
    ],
  ),
  PaymentMethodModel(
    id: 'shopeepay',
    name: 'ShopeePay',
    shortName: 'SPY',
    isVirtualAccount: false,
    color: const Color(0xFFEE4D2D),
    steps: [
      'Pastikan aplikasi Shopee terinstal di HP kamu.',
      'Tekan tombol "Bayar Sekarang" di bawah.',
      'Kamu akan diarahkan ke aplikasi Shopee secara otomatis.',
      'Konfirmasi nominal dan masukkan PIN ShopeePay kamu.',
      'Tunggu hingga status pembayaran berubah menjadi sukses.',
    ],
  ),
  PaymentMethodModel(
    id: 'gopay',
    name: 'GoPay',
    shortName: 'GPY',
    isVirtualAccount: false,
    color: const Color(0xFF00AED6),
    steps: [
      'Pastikan aplikasi Gojek atau GoPay terinstal.',
      'Tekan tombol "Bayar Sekarang" di bawah.',
      'Aplikasi akan membuka GoPay untuk menyelesaikan transaksi.',
      'Masukkan PIN GoPay.',
      'Selesai! Pembayaran akan terverifikasi otomatis.',
    ],
  ),
];

// 2. HALAMAN PILIH METODE PEMBAYARAN
class ChoosePaymentPage extends StatelessWidget {
  final String orderId;
  final int totalPrice;
  final String serviceName;
  final String clientName;

  const ChoosePaymentPage({
    super.key,
    required this.orderId,
    required this.totalPrice,
    required this.serviceName,
    required this.clientName,
  });

  String _formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Pilih Pembayaran',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringkasan Tagihan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(totalPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Text(
                    'Layanan: $serviceName',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // List Metode Pembayaran
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paymentOptions.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final method = paymentOptions[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 32,
                      decoration: BoxDecoration(
                        color: method.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          method.shortName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      method.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      // Pindah ke halaman pembayaran spesifik
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            orderId: orderId,
                            totalPrice: totalPrice,
                            serviceName: serviceName,
                            clientName: clientName,
                            selectedPayment: method, // Kirim metode yang dipilih
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. HALAMAN PEMBAYARAN SPESIFIK
class PaymentPage extends StatefulWidget {
  final String orderId;
  final int totalPrice;
  final String serviceName;
  final String clientName;
  final PaymentMethodModel selectedPayment; 

  const PaymentPage({
    super.key,
    required this.orderId,
    required this.totalPrice,
    required this.serviceName,
    required this.clientName,
    required this.selectedPayment,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late final String _vaNumber;
  late final String _merchantOrderId;

  static const int _expirySeconds = 24 * 60 * 60; // 24 Jam
  int _secondsLeft = _expirySeconds;
  Timer? _countdownTimer;

  bool _isConfirming = false;
  bool _paymentSuccess = false;
  bool _expired = false;

  late AnimationController _checkController;
  late Animation<double> _checkScale;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    final ts = DateTime.now().millisecondsSinceEpoch;
    _vaNumber = '8277 0000 ${_fmtVaPart(ts)}';
    _merchantOrderId = 'SIM$ts';

    _startCountdown();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _checkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _fmtVaPart(int ts) {
    final s = (ts % 100000000).toString().padLeft(8, '0');
    return '${s.substring(0, 4)} ${s.substring(4)}';
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _expired = true;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  String get _timerLabel {
    final h = _secondsLeft ~/ 3600;
    final m = (_secondsLeft % 3600) ~/ 60;
    final s = _secondsLeft % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatRupiah(int v) {
    final str = v.toString();
    final buf = StringBuffer('Rp ');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  Future<void> _simulatePay() async {
    if (_expired) {
      _showSnack('Waktu pembayaran telah habis.', isError: true);
      return;
    }
    setState(() => _isConfirming = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      await supabase.from('orders').update({
        'payment_status': 'paid',
        'work_status': 'progress',
        'merchant_order_id': _merchantOrderId,
      }).eq('id', widget.orderId);

      _countdownTimer?.cancel();
      setState(() {
        _paymentSuccess = true;
        _isConfirming = false;
      });
      _checkController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        _showSnack('Gagal konfirmasi pembayaran: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF1A237E),
    ));
  }

  void _copyVa() {
    Clipboard.setData(ClipboardData(text: _vaNumber.replaceAll(' ', '')));
    _showSnack('Nomor VA disalin ke clipboard');
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentSuccess) return _buildSuccessScreen();
    if (_expired) return _buildExpiredScreen();
    return _buildPaymentScreen();
  }

  Widget _buildPaymentScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Instruksi Pembayaran',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _timerCard(),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Detail Pesanan'),
                  const Divider(),
                  _infoRow('No. Order', _merchantOrderId),
                  _infoRow('Layanan', widget.serviceName),
                  const Divider(),
                  _infoRow(
                    'Total',
                    _formatRupiah(widget.totalPrice),
                    valueBold: true,
                    valueColor: const Color(0xFF1A237E),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.selectedPayment.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            widget.selectedPayment.shortName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.selectedPayment.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Render Virtual Account UI atau E-Wallet UI
                  if (widget.selectedPayment.isVirtualAccount) ...[
                    const Text(
                      'Nomor Virtual Account',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: GestureDetector(
                        onTap: _copyVa,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF1A237E).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _vaNumber,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Color(0xFF1A237E),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const Icon(Icons.copy,
                                  color: Color(0xFF1A237E), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ketuk untuk menyalin nomor VA',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.selectedPayment.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: widget.selectedPayment.color.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_scanner,
                              size: 48, color: widget.selectedPayment.color),
                          const SizedBox(height: 8),
                          Text(
                            'Pembayaran via Aplikasi',
                            style: TextStyle(
                              color: widget.selectedPayment.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _sectionTitle('Cara Pembayaran'),
                  const SizedBox(height: 10),
                  ...widget.selectedPayment.steps.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    String text = entry.value;
                    return _step(index.toString(), text);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isConfirming ? null : _simulatePay,
                child: _isConfirming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        widget.selectedPayment.isVirtualAccount
                            ? 'Konfirmasi Pembayaran'
                            : 'Bayar Sekarang',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                widget.selectedPayment.isVirtualAccount
                    ? 'Tekan setelah melakukan transfer'
                    : 'Otomatis membuka aplikasi ${widget.selectedPayment.name}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _checkScale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Order kamu sekarang sedang diproses. Pantau perkembangannya di halaman detail pesanan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.6),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow('Layanan', widget.serviceName),
                  const SizedBox(height: 6),
                  _infoRow(
                    'Jumlah',
                    _formatRupiah(widget.totalPrice),
                    valueBold: true,
                    valueColor: const Color(0xFF1A237E),
                  ),
                  const SizedBox(height: 6),
                  _infoRow('Status', 'Lunas',
                      valueBold: true, valueColor: Colors.green),
                  const SizedBox(height: 6),
                  _infoRow('Metode', widget.selectedPayment.name),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(initialIndex: 1),
                      ),
                      (route) => false, // Ini akan menyisakan halaman paling awal (biasanya Home) di riwayat bawahnya
                    );
                  },
                  child: const Text(
                    'Lihat Detail Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEEEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_off_outlined,
                  color: Colors.red, size: 52),
            ),
            const SizedBox(height: 24),
            const Text(
              'Waktu Habis',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Sesi pembayaran ini telah kadaluarsa. Silakan kembali dan buat order ulang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.6),
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A237E)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    // Kembali ke halaman Choose Payment, atau bisa disesuaikan ke Home
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      color: Color(0xFF1A237E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerCard() {
    final isLow = _secondsLeft < 3600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLow ? Colors.red.shade50 : const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow
              ? Colors.red.shade300
              : const Color(0xFF1A237E).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: isLow ? Colors.red : const Color(0xFF1A237E),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selesaikan pembayaran dalam',
              style: TextStyle(
                color: isLow ? Colors.red.shade700 : const Color(0xFF1A237E),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _timerLabel,
            style: TextStyle(
              color: isLow ? Colors.red : const Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      );

  Widget _infoRow(
    String label,
    String value, {
    bool valueBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          const Text(' : ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 12, top: 1),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
