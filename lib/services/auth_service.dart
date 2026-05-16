import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';

class AuthService {
  static final supabase = Supabase.instance.client;

  // REGISTER UNTUK CLIENT
  static Future<void> registerClient({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final existingPhone = await supabase
        .from('users')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();

    if (existingPhone != null) {
      throw Exception("Nomor telepon sudah digunakan oleh akun lain");
    }

    final AuthResponse response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception("Gagal membuat akun");

    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'role': 'client',
      'phone': phone,
    });
  }

  // REGISTER UNTUK TALENT
  static Future<void> registerTalent({
    required String name,
    required String email,
    required String password,
    required String phone,
    // Web pakai bytes, mobile pakai File
    File? cvPdf,
    Uint8List? cvPdfBytes,
    File? ktmImage,
    Uint8List? ktmImageBytes,
    String? ktmImageExt,
  }) async {
    final existingPhone = await supabase
        .from('users')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();

    if (existingPhone != null) {
      throw Exception("Nomor telepon sudah digunakan oleh akun lain");
    }


    final AuthResponse response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception("Gagal membuat akun");

    // Upload KTM
    final ktmFileName = 'ktm_${user.id}.${ktmImageExt ?? 'jpg'}';
    if (kIsWeb && ktmImageBytes != null) {
      await supabase.storage.from('dokumen_ktm').uploadBinary(
            ktmFileName,
            ktmImageBytes,
            fileOptions: FileOptions(
                contentType: 'image/${ktmImageExt ?? 'jpg'}', upsert: true),
          );
    } else if (ktmImage != null) {
      await supabase.storage
          .from('dokumen_ktm')
          .upload(ktmFileName, ktmImage,
              fileOptions: const FileOptions(upsert: true));
    }
    final ktmUrl =
        supabase.storage.from('dokumen_ktm').getPublicUrl(ktmFileName);

    // Upload CV
    final cvFileName = 'cv_${user.id}.pdf';
    if (kIsWeb && cvPdfBytes != null) {
      await supabase.storage.from('dokumen_cv').uploadBinary(
            cvFileName,
            cvPdfBytes,
            fileOptions:
                const FileOptions(contentType: 'application/pdf', upsert: true),
          );
    } else if (cvPdf != null) {
      await supabase.storage
          .from('dokumen_cv')
          .upload(cvFileName, cvPdf,
              fileOptions: const FileOptions(upsert: true));
    }
    final cvUrl =
        supabase.storage.from('dokumen_cv').getPublicUrl(cvFileName);

    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'role': 'talent',
      'phone': phone,
      'cv_portfolio': cvUrl,
      'ktm_url': ktmUrl,
    });
  }

  // LOGIN
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final AuthResponse response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user != null;
  }

  // LOGOUT
  static Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // CURRENT USER
  static User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // AMBIL ROLE USER
  static Future<String?> getCurrentRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    return data['role'];
  }

  // AMBIL DATA USER
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data =
        await supabase.from('users').select().eq('id', user.id).single();

    return data;
  }

  // CEK LOGIN
  static bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }
}