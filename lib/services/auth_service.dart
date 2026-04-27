import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    String role = "client",
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('${role}_name', name);
    await prefs.setString('${role}_email', email);
    await prefs.setString('${role}_password', password);
  }

  static Future<bool> login({
    required String email,
    required String password,
    String role = "client",
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('${role}_email');
    final savedPassword = prefs.getString('${role}_password');

    return email == savedEmail && password == savedPassword;
  }
}