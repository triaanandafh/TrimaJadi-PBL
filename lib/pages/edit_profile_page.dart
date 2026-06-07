import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _existingAvatarUrl;
  String? _existingKtmUrl;

  File?      _newAvatarFile;
  Uint8List? _newAvatarBytes;
  String?    _newAvatarExt;

  bool _isLoading = true;
  bool _isSaving  = false;

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
            .select('name, email, phone, avatar_url, ktm_url')
            .eq('id', user.id)
            .single();

        setState(() {
          _nameController.text  = data['name']  ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _existingAvatarUrl    = data['avatar_url'];
          _existingKtmUrl       = data['ktm_url'];
          _isLoading            = false;
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
    final fileName    = 'avatar_$userId.${_newAvatarExt ?? 'jpg'}';
    final contentType = 'image/${_newAvatarExt ?? 'jpg'}';
    late Uint8List bytes;

    if (kIsWeb) {
      if (_newAvatarBytes == null) return null;
      bytes = _newAvatarBytes!;
    } else {
      if (_newAvatarFile == null) return null;
      bytes = await _newAvatarFile!.readAsBytes();
    }

    await supabase.storage.from('avatars').uploadBinary(
      fileName,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    return supabase.storage.from('avatars').getPublicUrl(fileName);
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

        final hasNewAvatar =
            kIsWeb ? _newAvatarBytes != null : _newAvatarFile != null;
        if (hasNewAvatar) {
          final avatarUrl = await _uploadAvatar(user.id);
          if (avatarUrl != null) {
            updateData['avatar_url'] = avatarUrl;
            UserData.avatarUrl = avatarUrl;
          }
        }

        await supabase.from('users').update(updateData).eq('id', user.id);

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
            backgroundColor: Colors.red,
          ),
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

  // ─── Avatar preview ───────────────────────────────────────────────────────

  Widget _buildAvatarPreview() {
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
    if (_existingAvatarUrl != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_existingAvatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      child: const Icon(Icons.person, size: 70, color: Colors.white),
    );
  }

  // ─── KTM section (read-only) ──────────────────────────────────────────────

  Widget _buildKtmSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Foto Identitas (KTM)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Tidak dapat diubah',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _existingKtmUrl != null
                ? Image.network(
                    _existingKtmUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                          child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 40, color: Colors.grey.shade400),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada foto kartu tanda mahasiswa',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Avatar
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

                  _buildKtmSection(),
                  const SizedBox(height: 30),

                  _buildButton('Simpan'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
            : Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }
}