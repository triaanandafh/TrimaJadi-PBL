import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';

class EditServicePage extends StatefulWidget {
  final Map<String, dynamic> service;
  const EditServicePage({super.key, required this.service});

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final supabase = Supabase.instance.client;

  late TextEditingController titleController;
  late TextEditingController serviceDescriptionController;
  late TextEditingController basicDescController;
  late TextEditingController basicPriceController;
  late TextEditingController standardDescController;
  late TextEditingController standardPriceController;
  late TextEditingController premiumDescController;
  late TextEditingController premiumPriceController;

  List<Map<String, dynamic>> categories = [];
  String? selectedCategoryId;

  File? selectedImage;
  Uint8List? selectedImageBytes;
  String? selectedImageExt;
  String? existingImageUrl;

  bool isLoading = false;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.service['title'] ?? '');
    serviceDescriptionController = TextEditingController(text: widget.service['description'] ?? '');
    selectedCategoryId = widget.service['category_id'];
    existingImageUrl = widget.service['image_url'];

    final packages = widget.service['service_packages'] as List<dynamic>? ?? [];
    final basic = _getPackage(packages, 'basic');
    final standard = _getPackage(packages, 'standard');
    final premium = _getPackage(packages, 'premium');

    basicDescController = TextEditingController(text: basic?['package_description'] ?? '');
    basicPriceController = TextEditingController(text: basic?['price']?.toString() ?? '');
    standardDescController = TextEditingController(text: standard?['package_description'] ?? '');
    standardPriceController = TextEditingController(text: standard?['price']?.toString() ?? '');
    premiumDescController = TextEditingController(text: premium?['package_description'] ?? '');
    premiumPriceController = TextEditingController(text: premium?['price']?.toString() ?? '');

    fetchCategories();
  }

  Map<String, dynamic>? _getPackage(List<dynamic> packages, String type) {
    try {
      return packages.firstWhere((p) => p['package_type'] == type);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await supabase.from('categories').select().order('name');
      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil kategori: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoadingCategories = false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      selectedImageExt = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => selectedImageBytes = bytes);
      } else {
        setState(() => selectedImage = File(picked.path));
      }
    }
  }

  Future<String?> uploadImage(String serviceId) async {
    final fileName = '$serviceId.${selectedImageExt ?? 'jpg'}';
    final contentType = 'image/${selectedImageExt ?? 'jpg'}';
    late Uint8List bytes;

    if (kIsWeb) {
      if (selectedImageBytes == null) return null;
      bytes = selectedImageBytes!;
    } else {
      if (selectedImage == null) return null;
      bytes = await selectedImage!.readAsBytes();
    }

    await supabase.storage
        .from('service-images')
        .uploadBinary(fileName, bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true));

    return supabase.storage.from('service-images').getPublicUrl(fileName);
  }

  int? parsePrice(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.replaceAll('.', '').replaceAll(',', '').trim());
  }

  Future<void> _deleteService() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Layanan',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: const Text(
            'Yakin ingin menghapus layanan ini? Aksi ini tidak bisa dibatalkan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey)),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A43BF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Batal',
                  style: TextStyle(color: Color(0xFF1A43BF), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => isLoading = true);
      final serviceId = widget.service['id'];

      await supabase.from('service_packages').delete().eq('service_id', serviceId);
      await supabase.from('services').delete().eq('id', serviceId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Layanan berhasil dihapus")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> saveEdit() async {
    try {
      if (selectedCategoryId == null) throw Exception("Pilih kategori terlebih dahulu");
      if (titleController.text.trim().isEmpty) throw Exception("Judul layanan wajib diisi");

      final hasBasic = basicPriceController.text.trim().isNotEmpty;
      final hasStandard = standardPriceController.text.trim().isNotEmpty;
      final hasPremium = premiumPriceController.text.trim().isNotEmpty;
      if (!hasBasic && !hasStandard && !hasPremium) {
        throw Exception("Minimal isi 1 harga paket (Basic/Standard/Premium)");
      }

      setState(() => isLoading = true);

      final serviceId = widget.service['id'];

      String? imageUrl;
      final hasNewImage = kIsWeb ? selectedImageBytes != null : selectedImage != null;
      if (hasNewImage) {
        imageUrl = await uploadImage(serviceId);
      }

      await supabase.from('services').update({
        'category_id': selectedCategoryId,
        'title': titleController.text.trim(),
        'description': serviceDescriptionController.text.trim(),
        if (imageUrl != null) 'image_url': imageUrl,
      }).eq('id', serviceId);

      final packages = widget.service['service_packages'] as List<dynamic>? ?? [];

      Future<void> updatePackage(String type, TextEditingController desc,
          TextEditingController price) async {
        final existing = _getPackage(packages, type);
        if (existing != null) {
          await supabase.from('service_packages').update({
            'package_description': desc.text.trim().isEmpty ? null : desc.text.trim(),
            'price': parsePrice(price.text),
          }).eq('id', existing['id']);
        }
      }

      await updatePackage('basic', basicDescController, basicPriceController);
      await updatePackage('standard', standardDescController, standardPriceController);
      await updatePackage('premium', premiumDescController, premiumPriceController);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Layanan berhasil diupdate")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    serviceDescriptionController.dispose();
    basicDescController.dispose();
    basicPriceController.dispose();
    standardDescController.dispose();
    standardPriceController.dispose();
    premiumDescController.dispose();
    premiumPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Layanan",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _deleteService,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus Layanan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel("Foto Layanan"),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _buildImagePreview(),
              ),
            ),

            const SizedBox(height: 20),

            _sectionLabel("Kategori"),
            isLoadingCategories
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: const Text("Pilih kategori"),
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedCategoryId = value),
                  ),

            const SizedBox(height: 20),

            _sectionLabel("Judul Layanan"),
            _customTextField(controller: titleController, hint: "Judul layanan"),

            const SizedBox(height: 20),

            _sectionLabel("Deskripsi"),
            _customTextField(
                controller: serviceDescriptionController,
                hint: "Deskripsi layanan",
                maxLines: 4),

            const SizedBox(height: 20),

            _sectionLabel("Harga Paket"),
            const Text(
              "* Minimal isi 1 harga paket",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            _buildPriceTier("Basic", "Paket standar hemat",
                basicDescController, basicPriceController),
            _buildPriceTier("Standard", "Paket paling populer",
                standardDescController, standardPriceController),
            _buildPriceTier("Premium", "Layanan eksklusif & lengkap",
                premiumDescController, premiumPriceController),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A43BF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan Perubahan",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
      );
    }
    if (!kIsWeb && selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(selectedImage!, fit: BoxFit.cover),
      );
    }
    if (existingImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(existingImageUrl!, fit: BoxFit.cover),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text("Tap untuk pilih foto", style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _customTextField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[100]!)),
      ),
    );
  }

  Widget _buildPriceTier(
    String title,
    String subtitle,
    TextEditingController descController,
    TextEditingController priceController,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.workspace_premium,
            color: title == "Basic"
                ? Colors.blue
                : (title == "Standard" ? Colors.orange : Colors.purple)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _customTextField(
                    controller: descController,
                    hint: "Deskripsi paket $title",
                    maxLines: 3),
                const SizedBox(height: 12),
                _customTextField(
                    controller: priceController,
                    hint: "Harga paket $title (Rp)"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}