import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final serviceDescriptionController = TextEditingController();
  final basicDescController = TextEditingController();
  final basicPriceController = TextEditingController();
  final standardDescController = TextEditingController();
  final standardPriceController = TextEditingController();
  final premiumDescController = TextEditingController();
  final premiumPriceController = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  String? selectedCategoryId;

  File? selectedImage;
  Uint8List? selectedImageBytes;
  String? selectedImageExt;

  bool isLoading = false;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
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
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      // Ambil ext dari name, bukan path (aman untuk web)
      final name = picked.name;
      selectedImageExt = name.contains('.') ? name.split('.').last : 'jpg';
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
            fileOptions: FileOptions(contentType: contentType));

    return supabase.storage.from('service-images').getPublicUrl(fileName);
  }

  int? parsePrice(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.replaceAll('.', '').replaceAll(',', '').trim());
  }

  bool isPackageComplete({
    required TextEditingController descController,
    required TextEditingController priceController,
  }) {
    return descController.text.trim().isNotEmpty &&
        priceController.text.trim().isNotEmpty;
  }

  bool validatePackages() {
    return isPackageComplete(
          descController: basicDescController,
          priceController: basicPriceController,
        ) ||
        isPackageComplete(
          descController: standardDescController,
          priceController: standardPriceController,
        ) ||
        isPackageComplete(
          descController: premiumDescController,
          priceController: premiumPriceController,
        );
  }

  Future<void> saveService() async {
    try {
      if (selectedCategoryId == null) throw Exception("Pilih kategori terlebih dahulu");
      if (titleController.text.trim().isEmpty) throw Exception("Judul layanan wajib diisi");
      if (!validatePackages()) throw Exception("Minimal isi 1 paket lengkap (deskripsi + harga)");

      setState(() => isLoading = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User belum login");

      // INSERT SERVICE
      final serviceResponse = await supabase
          .from('services')
          .insert({
            'user_id': user.id,
            'category_id': selectedCategoryId,
            'title': titleController.text.trim(),
            'description': serviceDescriptionController.text.trim(),
          })
          .select()
          .single();

      final serviceId = serviceResponse['id'];

      // UPLOAD GAMBAR
      final imageUrl = await uploadImage(serviceId);

      // UPDATE image_url
      if (imageUrl != null) {
        await supabase
            .from('services')
            .update({'image_url': imageUrl}).eq('id', serviceId);
      }

      // INSERT PACKAGES
      await supabase.from('service_packages').insert([
        {
          'service_id': serviceId,
          'package_type': 'basic',
          'package_description': basicDescController.text.trim().isEmpty
              ? null
              : basicDescController.text.trim(),
          'price': parsePrice(basicPriceController.text),
        },
        {
          'service_id': serviceId,
          'package_type': 'standard',
          'package_description': standardDescController.text.trim().isEmpty
              ? null
              : standardDescController.text.trim(),
          'price': parsePrice(standardPriceController.text),
        },
        {
          'service_id': serviceId,
          'package_type': 'premium',
          'package_description': premiumDescController.text.trim().isEmpty
              ? null
              : premiumDescController.text.trim(),
          'price': parsePrice(premiumPriceController.text),
        },
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Layanan berhasil disimpan")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
        title: const Text("Tambah Layanan",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UPLOAD GAMBAR
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
                child: (kIsWeb ? selectedImageBytes != null : selectedImage != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                            : Image.file(selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text("Tap untuk pilih foto",
                              style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // KATEGORI
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

            // JUDUL
            _sectionLabel("Judul Layanan"),
            _customTextField(
                controller: titleController,
                hint: "Contoh: Desain Logo Minimalis"),

            const SizedBox(height: 20),

            // DESKRIPSI
            _sectionLabel("Deskripsi"),
            _customTextField(
                controller: serviceDescriptionController,
                hint: "Jelaskan detail layananmu...",
                maxLines: 4),

            const SizedBox(height: 20),

            // PAKET
            _sectionLabel("Harga Paket"),
            const SizedBox(height: 10),
            _buildPriceTier("Basic", "Paket standar hemat",
                basicDescController, basicPriceController),
            _buildPriceTier("Standard", "Paket paling populer",
                standardDescController, standardPriceController),
            _buildPriceTier("Premium", "Layanan eksklusif & lengkap",
                premiumDescController, premiumPriceController),

            const SizedBox(height: 40),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A43BF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan Layanan",
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
        leading: Icon(Icons.workspace_premium,
            color: title == "Basic"
                ? Colors.blue
                : (title == "Standard" ? Colors.orange : Colors.purple)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    hint: "Masukkan harga paket $title (Rp)"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}