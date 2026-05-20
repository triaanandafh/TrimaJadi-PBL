class UserData {
  static String name      = '';
  static String email     = '';
  static String role      = '';
  static String avatarUrl = '';
  static bool   isVerified = false;

  static void clear() {
    name       = '';
    email      = '';
    role       = '';
    avatarUrl  = '';
    isVerified = false;
  }
}
