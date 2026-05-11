import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class AuthService {
  static final supabase = Supabase.instance.client;

  // REGISTER UNTUK CLIENT
  static Future<void> registerClient({
    required String name,
    required String email,
    required String password,
  }) async {
    // Buat akun auth
    final AuthResponse response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception("Gagal membuat akun");
    }

    // Insert ke tabel users khusus Klien
    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'role': 'Client',
    });
  }

  // REGISTER UNTUK TALENT
  static Future<void> registerTalent({
    required String name,
    required String email,
    required String password,
    required String phone,
    required File cvPdf, 
    required File ktmImage,
  }) async {
    // Buat Akun Auth
    final AuthResponse response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    
    final user = response.user;
    if (user == null) {
      throw Exception("Gagal membuat akun");
    }

    // Upload Gambar KTM ke Storage
    final ktmFileName = 'ktm_${user.id}.jpg';
    await supabase.storage.from('dokumen_ktm').upload(ktmFileName, ktmImage);
    final ktmUrl = supabase.storage.from('dokumen_ktm').getPublicUrl(ktmFileName);

    // Upload File CV (PDF) ke Storage
    final cvFileName = 'cv_${user.id}.pdf';
    await supabase.storage.from('dokumen_cv').upload(cvFileName, cvPdf);
    final cvUrl = supabase.storage.from('dokumen_cv').getPublicUrl(cvFileName);

    // Insert data teks + URL gambar & PDF ke tabel users
    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'role': 'Talent',
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

    final data = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    return data;
  }

  // CEK LOGIN
  static bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }
}