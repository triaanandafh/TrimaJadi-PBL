import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final supabase = Supabase.instance.client;

  // REGISTER
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    // buat akun auth
    final AuthResponse response =
        await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception("Gagal membuat akun");
    }

    // insert ke tabel users
    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'email': email,
      'role': role,
    });
  }

  // LOGIN
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final AuthResponse response =
        await supabase.auth.signInWithPassword(
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
  static Future<Map<String, dynamic>?>
      getCurrentUserData() async {
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