import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_order_page.dart';

// Halaman ini dipanggil dari halaman detail layanan talent
// Contoh penggunaan:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => CreateOrderPage(serviceId: 'xxx'),
//   ));

class CreateOrderPage extends StatefulWidget {
  final String serviceId; // ID dari tabel services

  const CreateOrderPage({super.key, required this.serviceId});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>?       serviceData;
  Map<String, dynamic>?       talentData;
  List<Map<String, dynamic>>  packages   = [];

  String? selectedPackageId;
  int?    selectedPrice;
  String  selectedPackageType = '';
  String  selectedPackageDesc = '';

  final _descCtrl = TextEditingController();

  bool _isLoading       = true;
  bool _isSubmitting    = false;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetail();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  // ===== FETCH DATA LAYANAN =====
  Future<void> _fetchServiceDetail() async {
    try {
      // Ambil data service + packages + info talent
      final serviceResponse = await supabase
          .from('services')
          .select('''
            id, title, description, image_url,
            categories(name),
            service_packages(id, package_type, package_description, price),
            users(id, name, email, phone)
          ''')
          .eq('id', widget.serviceId)
          .single();

      final pkgs = (serviceResponse['service_packages'] as List)
          .where((p) => p['price'] != null && p['package_description'] != null)
          .map((p) => Map<String, dynamic>.from(p))
          .toList();

      // Urutkan basic → standard → premium
      const order = ['basic', 'standard', 'premium'];
      pkgs.sort((a, b) =>
          order.indexOf(a['package_type']) - order.indexOf(b['package_type']));

      setState(() {
        serviceData = serviceResponse;
        talentData  = serviceResponse['users'] as Map<String, dynamic>?;
        packages    = pkgs;
        isLoading   = false;

        // Auto-select paket pertama kalau ada
        if (pkgs.isNotEmpty) {
          selectedPackageId   = pkgs[0]['id'].toString();
          selectedPrice       = (pkgs[0]['price'] as num).toInt();
          selectedPackageType = pkgs[0]['package_type']?.toString() ?? '';
          selectedPackageDesc = pkgs[0]['package_description']?.toString() ?? '';
        }
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memuat layanan: $e', isError: true);
        setState(() => isLoading = false);
      }
    }
  }

  bool get isLoading => _isLoading;
  set isLoading(bool v) => _isLoading = v;

  // ===== SUBMIT ORDER =====
  Future<void> _submitOrder() async {
    if (selectedPackageId == null || selectedPrice == null) {
      _showSnackBar('Pilih paket terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final clientId = supabase.auth.currentUser?.id;
      final talentId = talentData?['id']?.toString();

      if (clientId == null) {
        _showSnackBar('Silakan login terlebih dahulu', isError: true);
        return;
      }
      if (talentId == null) {
        _showSnackBar('Data talent tidak ditemukan', isError: true);
        return;
      }

      final now      = DateTime.now();
      // Durasi default berdasarkan paket (bisa disesuaikan)
      final duration = selectedPackageType == 'premium'
          ? 7
          : selectedPackageType == 'standard'
              ? 5
              : 3;
      final deadline = now.add(Duration(days: duration));

      // Insert order ke Supabase
      final response = await supabase.from('orders').insert({
        'client_id'     : clientId,
        'talent_id'     : talentId,
        'service_name'  : '${serviceData!['title']} - Paket ${_capitalize(selectedPackageType)}',
        'description'   : _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : selectedPackageDesc,
        'total_price'   : selectedPrice,
        'duration'      : duration,
        'order_date'    : now.toIso8601String().substring(0, 10),
        'deadline'      : deadline.toIso8601String().substring(0, 10),
        'payment_status': 'unpaid',
        'work_status'   : 'pending',
      }).select().single();

      if (mounted) {
        _showSnackBar('Order berhasil dibuat!');
        await Future.delayed(const Duration(milliseconds: 400));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DetailOrderPage(
                orderId  : response['id'].toString(),
                isTalent : false,
                status   : 'pending',
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showSnackBar('Gagal membuat order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Pesan Layanan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : serviceData == null
              ? const Center(child: Text('Layanan tidak ditemukan'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ===== INFO LAYANAN =====
                            _card(
                              child: Row(
                                children: [
                                  // Gambar layanan
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: serviceData!['image_url'] != null
                                        ? Image.network(
                                            serviceData!['image_url'],
                                            width: 80, height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _placeholderImage(),
                                          )
                                        : _placeholderImage(),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          serviceData!['categories']?['name']?.toString() ?? '',
                                          style: TextStyle(
                                              color: Colors.grey[500], fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          serviceData!['title']?.toString() ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'oleh ${talentData?['name'] ?? '-'}',
                                          style: TextStyle(
                                              color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ===== PILIH PAKET =====
                            const Text(
                              'Pilih Paket',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 10),

                            if (packages.isEmpty)
                              const Text('Belum ada paket tersedia.')
                            else
                              ...packages.map((pkg) {
                                final pkgId   = pkg['id'].toString();
                                final pkgType = pkg['package_type']?.toString() ?? '';
                                final pkgDesc = pkg['package_description']?.toString() ?? '';
                                final pkgPrice = (pkg['price'] as num).toInt();
                                final isSelected = selectedPackageId == pkgId;

                                return GestureDetector(
                                  onTap: () => setState(() {
                                    selectedPackageId   = pkgId;
                                    selectedPrice       = pkgPrice;
                                    selectedPackageType = pkgType;
                                    selectedPackageDesc = pkgDesc;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2C4A6E)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2C4A6E)
                                            : Colors.grey[200]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon paket
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withOpacity(0.2)
                                                : _packageColor(pkgType).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            _packageIcon(pkgType),
                                            color: isSelected
                                                ? Colors.white
                                                : _packageColor(pkgType),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _capitalize(pkgType),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                pkgDesc,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isSelected
                                                      ? Colors.white70
                                                      : Colors.grey[600],
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _formatRupiah(pkgPrice),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF2C4A6E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                            const SizedBox(height: 16),

                            // ===== CATATAN TAMBAHAN =====
                            _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Catatan untuk Talent (opsional)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _descCtrl,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Jelaskan kebutuhanmu secara detail...',
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400], fontSize: 13),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: Colors.grey[200]!),
                                      ),
                                      contentPadding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ===== RINGKASAN ORDER =====
                            if (selectedPrice != null)
                              _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ringkasan Pesanan',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    const Divider(),
                                    _summaryRow(
                                      'Layanan',
                                      serviceData!['title']?.toString() ?? '-',
                                    ),
                                    _summaryRow(
                                      'Paket',
                                      _capitalize(selectedPackageType),
                                    ),
                                    _summaryRow(
                                      'Talent',
                                      talentData?['name']?.toString() ?? '-',
                                    ),
                                    const Divider(),
                                    _summaryRow(
                                      'Total',
                                      _formatRupiah(selectedPrice),
                                      isBold: true,
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),

                    // ===== TOMBOL ORDER =====
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedPrice != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pembayaran',
                                    style: TextStyle(color: Colors.grey)),
                                Text(
                                  _formatRupiah(selectedPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2C4A6E),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C4A6E),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isSubmitting ? null : _submitOrder,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text(
                                      'Pesan & Lanjut Bayar',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
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

  // ===== COMPONENTS =====
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 15 : 13,
              color: isBold ? const Color(0xFF2C4A6E) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image, color: Color(0xFF1A43BF), size: 32),
    );
  }

  Color _packageColor(String type) {
    switch (type) {
      case 'premium':  return Colors.purple;
      case 'standard': return Colors.orange;
      default:         return Colors.blue;
    }
  }

  IconData _packageIcon(String type) {
    switch (type) {
      case 'premium':  return Icons.workspace_premium;
      case 'standard': return Icons.star;
      default:         return Icons.check_circle_outline;
    }
  }
}
