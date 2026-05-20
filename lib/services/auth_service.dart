import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  // ──────────────────────────────────────────────
  // REGISTER CLIENT
  // ──────────────────────────────────────────────
  static Future<void> registerClient({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final existing = await _supabase
        .from('users')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Nomor telepon sudah digunakan oleh akun lain');
    }

    final res = await _supabase.auth.signUp(email: email, password: password);
    final user = res.user ?? (throw Exception('Gagal membuat akun'));

    await _supabase.from('users').insert({
      'id'   : user.id,
      'name' : name,
      'email': email,
      'role' : 'client',
      'phone': phone,
    });
  }

  // ──────────────────────────────────────────────
  // REGISTER TALENT
  // ──────────────────────────────────────────────
  static Future<void> registerTalent({
    required String name,
    required String email,
    required String password,
    required String phone,
    File?       cvPdf,
    Uint8List?  cvPdfBytes,
    File?       ktmImage,
    Uint8List?  ktmImageBytes,
    String?     ktmImageExt,
  }) async {
    final existing = await _supabase
        .from('users')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Nomor telepon sudah digunakan oleh akun lain');
    }

    final res = await _supabase.auth.signUp(email: email, password: password);
    final user = res.user ?? (throw Exception('Gagal membuat akun'));

    // Upload KTM
    final ktmExt      = ktmImageExt ?? 'jpg';
    final ktmFileName = 'ktm_${user.id}.$ktmExt';

    if (kIsWeb && ktmImageBytes != null) {
      await _supabase.storage.from('dokumen_ktm').uploadBinary(
            ktmFileName,
            ktmImageBytes,
            fileOptions: FileOptions(
                contentType: 'image/$ktmExt', upsert: true),
          );
    } else if (ktmImage != null) {
      await _supabase.storage.from('dokumen_ktm').upload(
            ktmFileName,
            ktmImage,
            fileOptions: const FileOptions(upsert: true),
          );
    }
    final ktmUrl =
        _supabase.storage.from('dokumen_ktm').getPublicUrl(ktmFileName);

    // Upload CV
    final cvFileName = 'cv_${user.id}.pdf';

    if (kIsWeb && cvPdfBytes != null) {
      await _supabase.storage.from('dokumen_cv').uploadBinary(
            cvFileName,
            cvPdfBytes,
            fileOptions:
                const FileOptions(contentType: 'application/pdf', upsert: true),
          );
    } else if (cvPdf != null) {
      await _supabase.storage.from('dokumen_cv').upload(
            cvFileName,
            cvPdf,
            fileOptions: const FileOptions(upsert: true),
          );
    }
    final cvUrl =
        _supabase.storage.from('dokumen_cv').getPublicUrl(cvFileName);

    await _supabase.from('users').insert({
      'id'           : user.id,
      'name'         : name,
      'email'        : email,
      'role'         : 'talent',
      'phone'        : phone,
      'cv_portfolio' : cvUrl,
      'ktm_url'      : ktmUrl,
      'is_verified'  : false,
    });
  }

  // ──────────────────────────────────────────────
  // LOGIN
  // ──────────────────────────────────────────────
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth
        .signInWithPassword(email: email, password: password);
    return res.user != null;
  }

  // ──────────────────────────────────────────────
  // LOGOUT
  // ──────────────────────────────────────────────
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────
  static User? getCurrentUser() => _supabase.auth.currentUser;

  static bool isLoggedIn() => _supabase.auth.currentUser != null;

  static Future<String?> getCurrentRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final data = await _supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    return data['role'] as String?;
  }

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
  }
}
