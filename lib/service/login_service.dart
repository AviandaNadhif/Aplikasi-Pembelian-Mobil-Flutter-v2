import '../helpers/user_info.dart';
import 'user_service.dart';
import '../model/user.dart';

/// Layanan service untuk otentikasi login pengguna dengan kredensial email dan password.
class LoginService {
  /// Melakukan verifikasi [email] dan [password] pengguna ke REST API dan menginisialisasi sesi lokal.
  Future<bool> login(String email, String password) async {
    bool isLogin = false;
    try {
      final List<User> users = await UserService().listData();
      final userMatch = users.firstWhere(
        (u) => u.email == email,
        orElse: () => User(name: '', email: '', phone: '', password: ''),
      );

      // Email tidak ditemukan
      if (userMatch.email.isEmpty) return false;

      if (userMatch.email.trim().toLowerCase() == 'aviandanadhif25@gmail.com') {
        userMatch.role = 'admin';
      }

      // 1. Jika password di DB ada/set, harus cocok dengan password input
      if (userMatch.password.isNotEmpty) {
        if (userMatch.password == password) {
          await UserInfo().setToken("token_${userMatch.email}");
          await UserInfo().setUserID(userMatch.id.isNotEmpty ? userMatch.id : userMatch.email);
          await UserInfo().setUsername(userMatch.name);
          await UserInfo().setEmail(userMatch.email);
          await UserInfo().setRole(userMatch.role);
          isLogin = true;
        }
      } else {
        // 2. Jika akun terdaftar via Google (password DB masih kosong),
        // izinkan login biasa & jadikan password input ini sebagai password barunya
        userMatch.password = password;
        await UserService().ubah(userMatch, userMatch.id);

        await UserInfo().setToken("token_${userMatch.email}");
        await UserInfo().setUserID(userMatch.id.isNotEmpty ? userMatch.id : userMatch.email);
        await UserInfo().setUsername(userMatch.name);
        await UserInfo().setEmail(userMatch.email);
        await UserInfo().setRole(userMatch.role);
        isLogin = true;
      }
    } catch (e) {
      rethrow;
    }
    return isLogin;
  }
}
