import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';

class RegisterTalentPage extends StatefulWidget {
  const RegisterTalentPage({super.key});

  @override
  State<RegisterTalentPage> createState() => _RegisterTalentPageState();
}

class _RegisterTalentPageState extends State<RegisterTalentPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  // KTM
  File? ktmImage;
  Uint8List? ktmImageBytes;
  String? ktmImageExt;
  final ImagePicker _picker = ImagePicker();

  // CV
  File? cvPdfFile;
  Uint8List? cvPdfBytes;
  String? cvFileName;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickKTMImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      ktmImageExt = pickedFile.name.contains('.')
          ? pickedFile.name.split('.').last
          : 'jpg';
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => ktmImageBytes = bytes);
      } else {
        setState(() => ktmImage = File(pickedFile.path));
      }
    }
  }

  Future<void> _pickCVPdf() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // penting untuk web
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          cvPdfBytes = result.files.single.bytes;
          cvFileName = result.files.single.name;
        });
      }
    } else {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          cvPdfFile = File(result.files.single.path!);
          cvFileName = result.files.single.name;
        });
      }
    }
  }

  Future<void> _register() async {
    final hasKtm = kIsWeb ? ktmImageBytes != null : ktmImage != null;
    final hasCv = kIsWeb ? cvPdfBytes != null : cvPdfFile != null;

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        !hasKtm ||
        !hasCv) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi semua data, upload KTM, dan upload CV'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await AuthService.registerTalent(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        cvPdf: kIsWeb ? null : cvPdfFile,
        cvPdfBytes: kIsWeb ? cvPdfBytes : null,
        ktmImage: kIsWeb ? null : ktmImage,
        ktmImageBytes: kIsWeb ? ktmImageBytes : null,
        ktmImageExt: ktmImageExt,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    String? note,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscurePassword : false,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: Colors.orange),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note,
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    final hasKtm = kIsWeb ? ktmImageBytes != null : ktmImage != null;
    final hasCv = kIsWeb ? cvPdfBytes != null : cvPdfFile != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // PERUBAHAN 1: Hapus padding: const EdgeInsets.all(20) dari sini agar header bisa full
          padding: EdgeInsets.zero, 
          child: Column(
            children: [
              // HEADER GRADASI (Sekarang beneran full edge-to-edge!)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40, // Ditambah sedikit biar proporsional dan tinggi seperti halaman masuk
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1A237E), // Deep Blue
                      Color(0xFF283593), // Indigo
                      Color(0xFF3949AB), // Light Indigo
                    ],
                    stops: [0.0, 0.5, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Daftar sebagai Talent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Diperbesar sedikit biar makin tegas
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Langkah awal tunjukkan keahlian terbaikmu',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // PERUBAHAN 2: Bungkus semua inputan di bawah header dengan Padding 20
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    sectionTitle("Data Akun"),
                    const SizedBox(height: 15),

                    buildInputField(
                      label: "Nama Lengkap *",
                      icon: Icons.person_outline,
                      controller: nameController,
                    ),
                    const SizedBox(height: 15),

                    buildInputField(
                      label: "E-mail *",
                      icon: Icons.email_outlined,
                      controller: emailController,
                    ),
                    const SizedBox(height: 15),

                    buildInputField(
                      label: "Password *",
                      icon: Icons.lock_outline,
                      controller: passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 15),

                    buildInputField(
                      label: "Nomor Telepon",
                      icon: Icons.phone_outlined,
                      controller: phoneController,
                    ),

                    const SizedBox(height: 25),

                    sectionTitle("Dokumen Pendukung"),
                    const SizedBox(height: 15),

                    // WIDGET UPLOAD FOTO KTM
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Upload Foto Identitas (KTM / KTP) *",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickKTMImage,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ktmImage != null ? Colors.transparent : Colors.grey.shade400,
                            style: ktmImage != null ? BorderStyle.none : BorderStyle.solid,
                          ),
                        ),
                        child: ktmImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  ktmImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade500),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Ketuk untuk memilih foto",
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // WIDGET UPLOAD CV (PDF)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Upload CV / Portfolio (PDF) *",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickCVPdf,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cvPdfFile != null ? Colors.blue : Colors.grey.shade400,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cvPdfFile != null ? Icons.picture_as_pdf : Icons.upload_file, 
                              size: 40, 
                              color: cvPdfFile != null ? Colors.red : Colors.grey.shade500
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                cvPdfFile != null ? cvFileName! : "Ketuk untuk memilih file PDF",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: cvPdfFile != null ? Colors.black87 : Colors.grey.shade600,
                                  fontWeight: cvPdfFile != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // TOMBOL DAFTAR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE88A2F),
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Daftar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // LOGIN ACCOUNT TRIGGER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }}