import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// KONFIGURASI DUITKU 
class _DuitkuConfig {
  static const String merchantCode = 'DS30597';      // Merchant Code dari dashboard Duitku
  static const String apiKey       = '6826f8de299f58979d82e49a6a1dbae1'; // API Key dari dashboard Duitku

  // Sandbox untuk testing
  static const String baseUrl = 'https://sandbox.duitku.com/webapi/api/merchant';
}

class DetailOrderPage extends StatefulWidget {
  final String orderId; // ID order dari database Supabase
  final bool isTalent;
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
  bool isLoading = true;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  // FETCH DATA ORDER
  Future<void> _fetchOrderDetails() async {
    try {
      final orderResponse = await supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      final otherUserId = widget.isTalent
          ? orderResponse['client_id']
          : orderResponse['talent_id'];

      final userResponse = await supabase
          .from('users')
          .select('name, phone, email')
          .eq('id', otherUserId)
          .single();

      setState(() {
        orderData    = orderResponse;
        otherUserData = userResponse;
        isLoading    = false;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memuat data: $e', isError: true);
        setState(() => isLoading = false);
      }
    }
  }

  // DUITKU: BUAT TRANSAKSI
  Future<void> _handlePayment() async {
    setState(() => _isProcessingPayment = true);

    try {
      final int amount         = (orderData!['total_price'] as num).toInt();
      final String orderId     = widget.orderId;
      final String productName = orderData!['service_name'] ?? 'Pembayaran Layanan';
      final String email       = otherUserData!['email'] ?? '';
      final String name        = otherUserData!['name'] ?? 'Client';

      // Signature MD5: merchantCode + amount + merchantOrderId + apiKey
      final rawSig  = '${_DuitkuConfig.merchantCode}$amount$orderId${_DuitkuConfig.apiKey}';
      final signature = md5.convert(utf8.encode(rawSig)).toString();

      final body = jsonEncode({
        'merchantCode'   : _DuitkuConfig.merchantCode,
        'paymentAmount'  : amount,
        'paymentMethod'  : 'VC',       // VC = semua metode (QRIS, VA, dll)
        'merchantOrderId': orderId,
        'productDetails' : productName,
        'customerVaName' : name,
        'email'          : email,
        'callbackUrl'    : 'https://cbzpffxxllkllgirepcz.supabase.co/functions/v1/duitku-callback',
        'returnUrl'      : 'https://cbzpffxxllkllgirepcz.supabase.co/functions/v1/duitku-callback', 
        'expiryPeriod'   : 1440, // menit (24 jam)
        'signature'      : signature,
      });

      final response = await _httpPost(
        '${_DuitkuConfig.baseUrl}/createInvoice',
        body,
      );

      if (response == null) {
        _showSnackBar('Gagal terhubung ke server pembayaran', isError: true);
        return;
      }

      final data = jsonDecode(response);

      if (data['statusCode'] == '00') {
        // Simpan referensi Duitku & ubah status jadi 'pending' di Supabase
        await supabase.from('orders').update({
          'payment_status'   : 'pending',
          'duitku_reference' : data['reference'],
        }).eq('id', orderId);

        // Refresh data lokal
        setState(() {
          orderData!['payment_status']    = 'pending';
          orderData!['duitku_reference']  = data['reference'];
        });

        // Buka halaman pembayaran Duitku di browser
        final url = Uri.parse(data['paymentUrl'] as String);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('Tidak bisa membuka halaman pembayaran', isError: true);
        }
      } else {
        _showSnackBar(
          data['statusMessage'] ?? 'Pembuatan transaksi gagal',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // DUITKU: CEK STATUS PEMBAYARAN
  Future<void> _checkPaymentStatus() async {
    setState(() => _isProcessingPayment = true);

    try {
      final String orderId = widget.orderId;
      final rawSig = '${_DuitkuConfig.merchantCode}$orderId${_DuitkuConfig.apiKey}';
      final signature = md5.convert(utf8.encode(rawSig)).toString();

      final body = jsonEncode({
        'merchantCode'   : _DuitkuConfig.merchantCode,
        'merchantOrderId': orderId,
        'signature'      : signature,
      });

      final response = await _httpPost(
        '${_DuitkuConfig.baseUrl}/transactionStatus',
        body,
      );

      if (response == null) {
        _showSnackBar('Gagal mengecek status', isError: true);
        return;
      }

      final data       = jsonDecode(response);
      final statusCode = data['statusCode'] as String? ?? 'ERROR';

      if (statusCode == '00') {
        // Pembayaran berhasil — update Supabase
        await supabase.from('orders').update({
          'payment_status': 'paid',
          'work_status'   : 'progress',
        }).eq('id', orderId);

        setState(() {
          orderData!['payment_status'] = 'paid';
          orderData!['work_status']    = 'progress';
        });

        _showSnackBar('Pembayaran berhasil! Order sedang diproses.');
      } else if (statusCode == '01') {
        _showSnackBar('Pembayaran masih pending. Silakan selesaikan pembayaran.');
      } else {
        _showSnackBar('Pembayaran gagal atau kadaluarsa.', isError: true);
        await supabase.from('orders').update({
          'payment_status': 'failed',
        }).eq('id', orderId);
        setState(() => orderData!['payment_status'] = 'failed');
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  // HTTP HELPER
  Future<String?> _httpPost(String url, String body) async {
    // Menggunakan HttpClient bawaan Dart agar tidak perlu import tambahan
    // Kalau sudah tambah package http: di pubspec, bisa pakai http.post()
    try {
      final uri    = Uri.parse(url);
      final client = await _createHttpClient();
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.write(body);
      final res     = await request.close();
      final resBody = await res.transform(utf8.decoder).join();
      client.close();
      return resBody;
    } catch (_) {
      return null;
    }
  }

  dynamic _createHttpClient() async {
    // ignore: deprecated_member_use
    return HttpClient();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text('Detail Order', style: TextStyle(color: Colors.black)),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderData == null || otherUserData == null
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
                                    widget.isTalent
                                        ? 'Informasi Client'
                                        : 'Informasi Talent',
                                    style: _titleStyle(),
                                  ),
                                  const SizedBox(height: 15),

                                  _row('Nama',         otherUserData!['name']  ?? '-'),
                                  _row('Nomor Telepon', otherUserData!['phone'] ?? '-'),
                                  _row('Email',        otherUserData!['email'] ?? '-'),

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

                                  _row('Nama Layanan',      orderData!['service_name']   ?? '-'),
                                  _row('Durasi',            '${orderData!['duration'] ?? '-'} hari'),
                                  _row('Tanggal Order',     orderData!['order_date']     ?? '-'),
                                  _row('Deadline',          orderData!['deadline']       ?? '-'),
                                  _row('Total Harga',       _formatRupiah(orderData!['total_price'])),
                                  _row('Status Pembayaran', _labelPaymentStatus(orderData!['payment_status'])),
                                  _row('Status Pengerjaan', orderData!['work_status']    ?? widget.status),

                                  // Tampilkan referensi Duitku kalau ada
                                  if ((orderData!['duitku_reference'] ?? '').toString().isNotEmpty)
                                    _row('Ref. Duitku', orderData!['duitku_reference'].toString()),
                                ],
                              ),
                            ),

                            const SizedBox(height: 15),

                            // DESKRIPSI 
                            _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Deskripsi', style: _titleStyle()),
                                  const SizedBox(height: 10),
                                  Text(orderData!['description'] ?? 'Tidak ada deskripsi.'),
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

  // BOTTOM BUTTON DINAMIS 
  Widget _buildBottomButton() {
    final paymentStatus = orderData?['payment_status'] ?? 'unpaid';
    final workStatus    = orderData?['work_status']    ?? widget.status;

    // CLIENT: belum bayar 
    if (!widget.isTalent && paymentStatus == 'unpaid') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: _blueButton(),
          onPressed: _isProcessingPayment ? null : _handlePayment,
          child: _isProcessingPayment
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Bayar Sekarang', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // CLIENT: pembayaran pending (sudah klik bayar, belum konfirmasi)
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Cek Status', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // CLIENT: pembayaran gagal 
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

    // CLIENT: sudah bayar, order selesai = terima / revisi
    if (!widget.isTalent && workStatus == 'done') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: () {
                // TODO: logika Ajukan Revisi
              },
              child: const Text('Ajukan Revisi'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: _blueButton(),
              onPressed: () {
                // TODO: logika Terima Hasil (update work_status → 'accepted')
              },
              child: const Text('Terima Hasil', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    // TALENT: sedang mengerjakan = submit hasil 
    if (widget.isTalent && workStatus == 'progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: _blueButton(),
          onPressed: () {
            // TODO: logika Submit Hasil (update work_status = 'done')
          },
          child: const Text('Submit Hasil', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return const SizedBox();
  }

  // FORMAT HELPERS

  String _formatRupiah(dynamic value) {
    if (value == null) return '-';
    final num amount = value is num ? value : num.tryParse(value.toString()) ?? 0;
    // Format sederhana tanpa package intl
    final str = amount.toInt().toString();
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

  // COMPONENTS 

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

  TextStyle _titleStyle() => const TextStyle(fontWeight: FontWeight.bold, fontSize: 14);

  ButtonStyle _orangeButton() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE68C3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      );

  ButtonStyle _blueButton() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C4A6E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      );
}
