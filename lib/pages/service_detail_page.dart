import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_order_page.dart';

class ServiceDetailPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Basic', 'Standard', 'Premium'];

  Map<String, dynamic>? _getPackage(String type) {
    final packages =
        widget.service['service_packages'] as List<dynamic>? ?? [];
    try {
      return packages.firstWhere((p) => p['package_type'] == type);
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Tidak tersedia';
    final p = (price as num).toDouble();
    return 'IDR ${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final talentName = widget.service['users']?['name'] ?? 'Talent';
    final title = widget.service['title'] ?? '';
    final imageUrl = widget.service['image_url'];
    final selectedType = _tabs[_selectedTab].toLowerCase();
    final selectedPackage = _getPackage(selectedType);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined,
                color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Talent
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: widget.service['users']
                                    ?['avatar_url'] !=
                                null
                            ? NetworkImage(
                                widget.service['users']['avatar_url'])
                            : null,
                        child:
                            widget.service['users']?['avatar_url'] == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(talentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text('4.9',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Gambar Layanan
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
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

                  // Tab Basic / Standard / Premium
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: List.generate(_tabs.length, (index) {
                        final isSelected = _selectedTab == index;
                        final pkg =
                            _getPackage(_tabs[index].toLowerCase());
                        final isAvailable = pkg != null &&
                            pkg['price'] != null;
                        return Expanded(
                          child: GestureDetector(
                            onTap: isAvailable
                                ? () =>
                                    setState(() => _selectedTab = index)
                                : null,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
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
                                _tabs[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF1A43BF)
                                      : isAvailable
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

                  // Konten Paket
                  selectedPackage == null || selectedPackage['price'] == null
                      ? Center(
                          child: Text(
                            'Paket ${_tabs[_selectedTab]} tidak tersedia',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Harga
                            Text(
                              _formatPrice(selectedPackage['price']),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A43BF),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Deskripsi paket
                            if (selectedPackage['package_description'] !=
                                null)
                              ...((selectedPackage['package_description']
                                          as String)
                                      .split('\n'))
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

          // Tombol Lanjutkan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selectedPackage == null ||
                        selectedPackage['price'] == null
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
                  backgroundColor: const Color(0xFF1A43BF),
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
    );
  }
}