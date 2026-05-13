import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _role = '';
  String? _existingCvUrl;
  String? _existingAvatarUrl;

  File? _newCvFile;
  String? _newCvFileName;

  File? _newAvatarFile;
  Uint8List? _newAvatarBytes;
  String? _newAvatarExt;

  bool _isLoading = true;
  bool _isSaving = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('users')
            .select('name, email, phone, role, cv_portfolio, avatar_url')
            .eq('id', user.id)
            .single();

        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _role = data['role'] ?? '';
          _existingCvUrl = data['cv_portfolio'];
          _existingAvatarUrl = data['avatar_url'];
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

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      _newAvatarExt = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _newAvatarBytes = bytes);
      } else {
        setState(() => _newAvatarFile = File(picked.path));
      }
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    final fileName = 'avatar_$userId.${_newAvatarExt ?? 'jpg'}';
    final contentType = 'image/${_newAvatarExt ?? 'jpg'}';
    late Uint8List bytes;

    if (kIsWeb) {
      if (_newAvatarBytes == null) return null;
      bytes = _newAvatarBytes!;
    } else {
      if (_newAvatarFile == null) return null;
      bytes = await _newAvatarFile!.readAsBytes();
    }

    await supabase.storage
        .from('avatars')
        .uploadBinary(fileName, bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true));

    return supabase.storage.from('avatars').getPublicUrl(fileName);
  }

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
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
        };

        // Upload avatar baru
        final hasNewAvatar =
            kIsWeb ? _newAvatarBytes != null : _newAvatarFile != null;
        if (hasNewAvatar) {
          final avatarUrl = await _uploadAvatar(user.id);
          if (avatarUrl != null) {
            updateData['avatar_url'] = avatarUrl;
            UserData.avatarUrl = avatarUrl; // update UserData
          }
        }

        // Upload CV baru (talent only)
        if (_newCvFile != null && _role.toLowerCase() == 'talent') {
          final cvFileName =
              'cv_${user.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          await supabase.storage
              .from('dokumen_cv')
              .upload(cvFileName, _newCvFile!);
          final cvUrl =
              supabase.storage.from('dokumen_cv').getPublicUrl(cvFileName);
          updateData['cv_portfolio'] = cvUrl;
        }

        await supabase.from('users').update(updateData).eq('id', user.id);

        // Update UserData.name
        UserData.name = _nameController.text.trim();

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
          SnackBar(
              content: Text('Gagal menyimpan: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildAvatarPreview() {
    // Gambar baru dipilih
    if (kIsWeb && _newAvatarBytes != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(_newAvatarBytes!),
      );
    }
    if (!kIsWeb && _newAvatarFile != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_newAvatarFile!),
      );
    }
    // Gambar existing dari Supabase
    if (_existingAvatarUrl != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_existingAvatarUrl!),
      );
    }
    // Default
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      child: const Icon(Icons.person, size: 70, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profil',
          style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar dengan tombol edit
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildAvatarPreview(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A43BF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap foto untuk mengganti',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    label: 'E-mail (Tidak dapat diubah)',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    label: 'Nomor Telepon (Tidak dapat diubah)',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),

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
                            color: _newCvFile != null
                                ? Colors.blue
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _newCvFile != null
                                  ? Icons.check_circle
                                  : (_existingCvUrl != null
                                      ? Icons.file_present
                                      : Icons.upload_file),
                              size: 35,
                              color: _newCvFile != null
                                  ? Colors.blue
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                _newCvFile != null
                                    ? _newCvFileName!
                                    : (_existingCvUrl != null
                                        ? "CV sudah terunggah. Ketuk untuk mengganti."
                                        : "Ketuk untuk memilih file PDF"),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  fontWeight: _newCvFile != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
              borderSide: BorderSide.none,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _isSaving ? null : _updateProfile,
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(text,
                style:
                    const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}