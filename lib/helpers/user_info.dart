import 'package:shared_preferences/shared_preferences.dart';

const String tokenKey = "token";
const String userIdKey = "userID";
const String usernameKey = "username";
const String emailKey = "email";
const String roleKey = "role";

/// Helper untuk mengelola sesi pengguna dan penyimpanan data lokal via [SharedPreferences].
class UserInfo {
  /// Menyimpan token autentikasi pengguna.
  Future<void> setToken(String value) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(tokenKey, value);
  }

  /// Mengambil token autentikasi pengguna yang tersimpan.
  Future<String?> getToken() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(tokenKey);
  }

  /// Menyimpan ID pengguna.
  Future<void> setUserID(String value) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(userIdKey, value);
  }

  /// Mengambil ID pengguna yang tersimpan.
  Future<String?> getUserID() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(userIdKey);
  }

  /// Menyimpan nama pengguna.
  Future<void> setUsername(String value) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(usernameKey, value);
  }

  /// Mengambil nama pengguna yang tersimpan.
  Future<String?> getUsername() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(usernameKey);
  }

  /// Menyimpan email pengguna.
  Future<void> setEmail(String value) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(emailKey, value);
  }

  /// Mengambil email pengguna yang tersimpan.
  Future<String?> getEmail() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(emailKey);
  }

  /// Menyimpan peran/role pengguna ('admin' atau 'user').
  Future<void> setRole(String value) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(roleKey, value);
  }

  /// Mengambil peran/role pengguna yang tersimpan.
  Future<String?> getRole() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(roleKey);
  }

  /// Menghapus seluruh data sesi lokal (logout).
  Future<void> logout() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.clear();
  }
}
