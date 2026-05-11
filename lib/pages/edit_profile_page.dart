import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controller untuk membaca dan mengisi teks di TextField
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); 

  // Variabel untuk menyimpan data tambahan dari database
  String _role = '';
  String? _existingCvUrl;

  // Variabel untuk menyimpan file CV baru yang dipilih
  File? _newCvFile;
  String? _newCvFileName;

  // Status loading
  bool _isLoading = true; 
  bool _isSaving = false; 

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. FUNGSI MENGAMBIL DATA DARI DATABASE
  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Mengambil data lengkap termasuk role dan cv_portfolio
        final data = await supabase
            .from('users')
            .select('name, email, phone, role, cv_portfolio') 
            .eq('id', user.id)
            .single();

        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? ''; 
          _role = data['role'] ?? '';
          _existingCvUrl = data['cv_portfolio'];
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. FUNGSI UNTUK MEMILIH CV BARU (PDF)
  Future<void> _pickNewCv() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], 
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _newCvFile = File(result.files.single.path!);
        _newCvFileName = result.files.single.name;
      });
    }
  }

  // 3. FUNGSI MENYIMPAN PERUBAHAN KE DATABASE
  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true); 

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Siapkan data teks yang mau diupdate
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
        };

        // Jika Talent mengunggah CV baru, kita upload ke Storage dulu
        if (_newCvFile != null && _role.toLowerCase() == 'talent') {
          // Tambahkan timestamp agar nama file unik dan tidak numpuk di cache
          final cvFileName = 'cv_${user.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          
          await supabase.storage.from('dokumen_cv').upload(cvFileName, _newCvFile!);
          final cvUrl = supabase.storage.from('dokumen_cv').getPublicUrl(cvFileName);
          
          // Tambahkan URL CV baru ke data yang mau diupdate
          updateData['cv_portfolio'] = cvUrl;
        }

        // Jalankan perintah Update ke tabel users
        await supabase.from('users').update(updateData).eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left), 
          onPressed: () => Navigator.pop(context)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profil', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60, 
                        backgroundColor: Colors.grey[300], 
                        child: const Icon(Icons.person, size: 70, color: Colors.white)
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white, 
                          shape: BoxShape.circle
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 20, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // TextField Nama (Bisa diedit)
                  _buildTextField(
                    label: 'Nama Lengkap', 
                    icon: Icons.person_outline,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 20),
                  
                  // TextField Email (Read-Only)
                  _buildTextField(
                    label: 'E-mail (Tidak dapat diubah)', 
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    readOnly: true, 
                  ),
                  const SizedBox(height: 20),

                  // TextField Nomor Telepon (Read-Only)
                  _buildTextField(
                    label: 'Nomor Telepon (Tidak dapat diubah)', 
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    readOnly: true, 
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // WIDGET UPDATE CV (HANYA MUNCUL JIKA TALENT)
                  // ==========================================
                  if (_role.toLowerCase() == 'talent') ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Update CV / Portfolio (PDF)",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickNewCv,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _newCvFile != null ? Colors.blue : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _newCvFile != null 
                                  ? Icons.check_circle 
                                  : (_existingCvUrl != null ? Icons.file_present : Icons.upload_file), 
                              size: 35, 
                              color: _newCvFile != null ? Colors.blue : Colors.grey[600]
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                _newCvFile != null 
                                    ? _newCvFileName! 
                                    : (_existingCvUrl != null ? "CV sudah terunggah. Ketuk untuk mengganti." : "Ketuk untuk memilih file PDF"),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  fontWeight: _newCvFile != null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  _buildButton('Simpan'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly, 
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: readOnly ? Colors.grey[300] : Colors.grey[200], 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), 
              borderSide: BorderSide.none
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
        ),
        onPressed: _isSaving ? null : _updateProfile,
        child: _isSaving 
            ? const SizedBox(
                height: 20, width: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}
