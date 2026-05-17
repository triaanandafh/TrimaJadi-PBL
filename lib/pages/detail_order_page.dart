import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// ============================================================
// KONFIGURASI DUITKU
// ============================================================
class _DuitkuConfig {
  static const String merchantCode = 'DS30597';
  static const String apiKey       = '6826f8de299f58979d82e49a6a1dbae1';
  static const String baseUrl      = 'https://sandbox.duitku.com/webapi/api/merchant';
  static const String callbackUrl  = 'https://cbzpffxxllkllgirepcz.supabase.co/functions/v1/duitku-callback';
  static const String returnUrl    = 'https://cbzpffxxllkllgirepcz.supabase.co/functions/v1/duitku-callback';
}
// ============================================================

class DetailOrderPage extends StatefulWidget {
  final String orderId;
  final bool   isTalent;
  final String status;

  const DetailOrderPage({
    super.key,
    required this.orderId,
    required this.isTalent,
    required this.status,
  });

  @override
  State<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends State<DetailOrderPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? orderData;
  Map<String, dynamic>? otherUserData;
  bool isLoading            = true;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  // ===== FETCH DATA =====
  Future<void> _fetchOrderDetails() async {
    setState(() => isLoading = true);
    try {
      final orderResponse = await supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      final otherUserId = widget.isTalent
          ? orderResponse['client_id']
          : orderResponse['talent_id'];

      Map<String, dynamic> userResponse = {
        'name' : '-',
        'phone': '-',
        'email': supabase.auth.currentUser?.email ?? 'test@email.com',
      };

      try {
        userResponse = await supabase
            .from('users')
            .select('name, phone, email')
            .eq('id', otherUserId)
            .single();
      } catch (_) {}

      setState(() {
        orderData     = orderResponse;
        otherUserData = userResponse;
        isLoading     = false;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memuat data: $e', isError: true);
        setState(() => isLoading = false);
      }
    }
  }

  // ===== DUITKU: BUAT TRANSAKSI =====
  Future<void> _handlePayment() async {
    setState(() => _isProcessingPayment = true);

    try {
      final int    amount      = (orderData!['total_price'] as num).toInt();
      final String productName = orderData!['service_name']?.toString() ?? 'Pembayaran Layanan';
      final String email       = supabase.auth.currentUser?.email ?? otherUserData?['email']?.toString() ?? 'user@email.com';
      final String name        = otherUserData?['name']?.toString() ?? 'Client';

      final String merchantOrderId = 'TJ${DateTime.now().millisecondsSinceEpoch}';

      final rawSig    = '${_DuitkuConfig.merchantCode}$amount$merchantOrderId${_DuitkuConfig.apiKey}';
      final signature = md5.convert(utf8.encode(rawSig)).toString();

      final body = jsonEncode({
        'merchantCode'   : _DuitkuConfig.merchantCode,
        'paymentAmount'  : amount,
        'paymentMethod'  : 'VC',
        'merchantOrderId': merchantOrderId,
        'productDetails' : productName,
        'customerVaName' : name,
        'email'          : email,
        'callbackUrl'    : _DuitkuConfig.callbackUrl,
        'returnUrl'      : _DuitkuConfig.returnUrl,
        'expiryPeriod'   : 1440,
        'signature'      : signature,
      });

      final httpResponse = await http.post(
        Uri.parse('${_DuitkuConfig.baseUrl}/createInvoice'),
        headers: {
          'Content-Type': 'application/json',
          'Accept'      : 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      final response = httpResponse.body;

      debugPrint('DUITKU RAW RESPONSE: $response');

      final data       = jsonDecode(response) as Map<String, dynamic>;
      final statusCode = data['statusCode']?.toString() ?? '';

      if (statusCode == '00') {
        final reference = (data['reference']
            ?? data['Reference']
            ?? data['merchantOrderId']
            ?? data['MerchantOrderId']
            ?? '').toString();

        debugPrint('REFERENCE TERSIMPAN: $reference');

        await supabase.from('orders').update({
          'payment_status'   : 'pending',
          'duitku_reference' : reference,
          'merchant_order_id': merchantOrderId,
        }).eq('id', widget.orderId);

        setState(() {
          orderData!['payment_status']    = 'pending';
          orderData!['duitku_reference']  = reference;
          orderData!['merchant_order_id'] = merchantOrderId;
        });

        final paymentUrl = (data['paymentUrl'] ?? data['PaymentUrl'] ?? '').toString();
        if (paymentUrl.isNotEmpty) {
          final url = Uri.parse(paymentUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            _showSnackBar('Tidak bisa membuka browser', isError: true);
          }
        }
      } else {
        final msg = data['statusMessage']?.toString() ?? 'Terjadi kesalahan';
        _showSnackBar('Pembayaran gagal: $msg', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // ===== DUITKU: CEK STATUS =====
  Future<void> _checkPaymentStatus() async {
    setState(() => _isProcessingPayment = true);

    try {
      final String merchantOrderId =
          orderData?['merchant_order_id']?.toString() ?? widget.orderId;

      final rawSig    = '${_DuitkuConfig.merchantCode}$merchantOrderId${_DuitkuConfig.apiKey}';
      final signature = md5.convert(utf8.encode(rawSig)).toString();

      final body = jsonEncode({
        'merchantCode'   : _DuitkuConfig.merchantCode,
        'merchantOrderId': merchantOrderId,
        'signature'      : signature,
      });

      final httpResponse = await http.post(
        Uri.parse('${_DuitkuConfig.baseUrl}/transactionStatus'),
        headers: {
          'Content-Type': 'application/json',
          'Accept'      : 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      final response = httpResponse.body;

      debugPrint('DUITKU STATUS RESPONSE: $response');

      final data       = jsonDecode(response) as Map<String, dynamic>;
      final statusCode = data['statusCode']?.toString() ?? 'ERROR';

      if (statusCode == '00') {
        await supabase.from('orders').update({
          'payment_status': 'paid',
          'work_status'   : 'progress',
        }).eq('id', widget.orderId);

        setState(() {
          orderData!['payment_status'] = 'paid';
          orderData!['work_status']    = 'progress';
        });

        _showSnackBar('Pembayaran dikonfirmasi! Order sedang diproses.');
      } else if (statusCode == '01') {
        _showSnackBar('Pembayaran masih menunggu. Selesaikan pembayaran terlebih dahulu.');
      } else {
        _showSnackBar('Pembayaran gagal atau kadaluarsa.', isError: true);
        await supabase.from('orders').update({
          'payment_status': 'failed',
        }).eq('id', widget.orderId);
        setState(() => orderData!['payment_status'] = 'failed');
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // ===== TALENT: SUBMIT HASIL =====
  Future<void> _showSubmitResultDialog() async {
    final linkCtrl  = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Submit Hasil Pekerjaan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Bagikan link hasil kerja (Google Drive, Dropbox, dll) dan catatan untuk client.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: linkCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Link Hasil Pekerjaan *',
                  hintText: 'https://drive.google.com/...',
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF2C4A6E)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C4A6E), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan untuk Client (opsional)',
                  hintText: 'Tuliskan catatan pengerjaan...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes, color: Color(0xFF2C4A6E)),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2C4A6E), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C4A6E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {
                    final link = linkCtrl.text.trim();
                    if (link.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Link hasil pekerjaan wajib diisi'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, {'link': link, 'notes': notesCtrl.text.trim()});
                  },
                  child: const Text(
                    'Kirim Hasil',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((result) async {
      if (result == null) return;
      setState(() => _isProcessingPayment = true);
      try {
        await supabase.from('orders').update({
          'work_status' : 'done',
          'result_link' : result['link'],
          'result_notes': result['notes'],
        }).eq('id', widget.orderId);

        setState(() {
          orderData!['work_status']  = 'done';
          orderData!['result_link']  = result['link'];
          orderData!['result_notes'] = result['notes'];
        });
        _showSnackBar('Hasil pekerjaan berhasil dikirim ke client!');
      } catch (e) {
        _showSnackBar('Gagal mengirim hasil: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isProcessingPayment = false);
      }
    });
  }

  // ===== CLIENT: TERIMA HASIL =====
  Future<void> _handleTerimaHasil() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terima Hasil?', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Dengan menerima hasil, order ini akan ditandai selesai. Pastikan Anda sudah memeriksa hasil pekerjaan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C4A6E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Terima', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isProcessingPayment = true);
    try {
      await supabase.from('orders').update({
        'work_status': 'accepted',
      }).eq('id', widget.orderId);
      setState(() => orderData!['work_status'] = 'accepted');
      _showSnackBar('Order selesai! Terima kasih telah menggunakan layanan ini.');
    } catch (e) {
      _showSnackBar('Gagal memperbarui status: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // ===== CLIENT: AJUKAN REVISI =====
  Future<void> _handleRevisi() async {
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ajukan Revisi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Jelaskan bagian mana yang perlu direvisi oleh talent.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: notesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Catatan Revisi *',
                hintText: 'Tuliskan detail revisi yang diinginkan...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2C4A6E), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () {
                  final notes = notesCtrl.text.trim();
                  if (notes.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Catatan revisi wajib diisi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, notes);
                },
                child: const Text('Kirim Permintaan Revisi',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ).then((notes) async {
      if (notes == null) return;
      setState(() => _isProcessingPayment = true);
      try {
        await supabase.from('orders').update({
          'work_status'   : 'progress',
          'revision_notes': notes,
        }).eq('id', widget.orderId);
        setState(() {
          orderData!['work_status']    = 'progress';
          orderData!['revision_notes'] = notes;
        });
        _showSnackBar('Permintaan revisi berhasil dikirim ke talent.');
      } catch (e) {
        _showSnackBar('Gagal mengirim revisi: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isProcessingPayment = false);
      }
    });
  }

  // ===== HELPERS =====
  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return '-';
    final num amount = value is num ? value : num.tryParse(value.toString()) ?? 0;
    final str    = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  String _labelPaymentStatus(dynamic status) {
    switch (status?.toString()) {
      case 'unpaid':  return 'Belum Dibayar';
      case 'pending': return 'Menunggu Pembayaran';
      case 'paid':    return 'Lunas ✓';
      case 'failed':  return 'Gagal';
      default:        return status?.toString() ?? '-';
    }
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text('Detail Order',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchOrderDetails,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderData == null
              ? const Center(child: Text('Data pesanan tidak ditemukan'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [

                            // INFO USER
                            _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isTalent ? 'Informasi Client' : 'Informasi Talent',
                                    style: _titleStyle(),
                                  ),
                                  const SizedBox(height: 15),
                                  _row('Nama',          otherUserData?['name']?.toString()  ?? '-'),
                                  _row('Nomor Telepon', otherUserData?['phone']?.toString() ?? '-'),
                                  _row('Email',         otherUserData?['email']?.toString() ?? '-'),
                                  if (widget.isTalent) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (_) => const Icon(Icons.star, color: Colors.amber, size: 16),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: _orangeButton(),
                                      onPressed: () {
                                        // TODO: navigasi ke ChatPage
                                      },
                                      child: Text(
                                        widget.isTalent ? 'Hubungi Client' : 'Hubungi Talent',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 15),

                            // DETAIL LAYANAN
                            _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Detail Layanan', style: _titleStyle()),
                                  const SizedBox(height: 15),
                                  _row('Nama Layanan',      orderData!['service_name']?.toString()  ?? '-'),
                                  _row('Durasi',            '${orderData!['duration'] ?? '-'} hari'),
                                  _row('Tanggal Order',     orderData!['order_date']?.toString()    ?? '-'),
                                  _row('Deadline',          orderData!['deadline']?.toString()      ?? '-'),
                                  _row('Total Harga',       _formatRupiah(orderData!['total_price'])),
                                  _row('Status Pembayaran', _labelPaymentStatus(orderData!['payment_status'])),
                                  _row('Status Pengerjaan', orderData!['work_status']?.toString()   ?? widget.status),
                                  if ((orderData!['duitku_reference'] ?? '').toString().isNotEmpty)
                                    _row('Ref. Pembayaran', orderData!['duitku_reference'].toString()),
                                ],
                              ),
                            ),

                            // HASIL PEKERJAAN
                            if ((orderData!['result_link'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 15),
                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.task_alt, color: Colors.green, size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Hasil Pekerjaan', style: _titleStyle()),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () async {
                                        final url = Uri.tryParse(orderData!['result_link'].toString());
                                        if (url != null && await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F0FF),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF1A43BF).withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.link, color: Color(0xFF1A43BF), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                orderData!['result_link'].toString(),
                                                style: const TextStyle(
                                                  color: Color(0xFF1A43BF),
                                                  decoration: TextDecoration.underline,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.open_in_new, color: Color(0xFF1A43BF), size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if ((orderData!['result_notes'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text('Catatan Talent:',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(orderData!['result_notes'].toString(),
                                          style: const TextStyle(fontSize: 13)),
                                    ],
                                    if ((orderData!['revision_notes'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.edit_note, color: Colors.orange, size: 18),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Catatan Revisi:',
                                                      style: TextStyle(
                                                          color: Colors.orange,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12)),
                                                  const SizedBox(height: 2),
                                                  Text(orderData!['revision_notes'].toString(),
                                                      style: const TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 15),

                            // DESKRIPSI
                            _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Deskripsi', style: _titleStyle()),
                                  const SizedBox(height: 10),
                                  Text(orderData!['description']?.toString() ?? 'Tidak ada deskripsi.'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // BOTTOM BUTTON
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: _buildBottomButton(),
                    ),
                  ],
                ),
    );
  }

  // ===== BOTTOM BUTTON =====
  Widget _buildBottomButton() {
    final paymentStatus = orderData?['payment_status']?.toString() ?? 'unpaid';
    final workStatus    = orderData?['work_status']?.toString()    ?? widget.status;

    // CLIENT: belum bayar
    if (!widget.isTalent && paymentStatus == 'unpaid') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: _blueButton(),
          onPressed: _isProcessingPayment ? null : _handlePayment,
          child: _isProcessingPayment
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Bayar Sekarang', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // CLIENT: menunggu konfirmasi
    if (!widget.isTalent && paymentStatus == 'pending') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Menunggu konfirmasi pembayaran...',
            style: TextStyle(color: Colors.orange, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: _isProcessingPayment ? null : _handlePayment,
                  child: const Text('Bayar Ulang'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: _blueButton(),
                  onPressed: _isProcessingPayment ? null : _checkPaymentStatus,
                  child: _isProcessingPayment
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Cek Status', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // CLIENT: bayar gagal
    if (!widget.isTalent && paymentStatus == 'failed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          onPressed: _isProcessingPayment ? null : _handlePayment,
          child: const Text('Coba Bayar Lagi', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // CLIENT: order selesai dikerjakan
    if (!widget.isTalent && workStatus == 'done') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _isProcessingPayment ? null : _handleRevisi,
              child: const Text('Ajukan Revisi'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: _blueButton(),
              onPressed: _isProcessingPayment ? null : _handleTerimaHasil,
              child: _isProcessingPayment
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Terima Hasil', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    // TALENT: sedang mengerjakan
    if (widget.isTalent && workStatus == 'progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: _blueButton(),
          onPressed: _isProcessingPayment ? null : _showSubmitResultDialog,
          icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
          label: const Text('Submit Hasil', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return const SizedBox();
  }

  // ===== COMPONENTS =====
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle   _titleStyle()   => const TextStyle(fontWeight: FontWeight.bold, fontSize: 14);

  ButtonStyle _orangeButton() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE68C3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      );

  ButtonStyle _blueButton()   => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C4A6E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      );
}
