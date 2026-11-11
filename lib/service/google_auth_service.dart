import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../helpers/api_client.dart';
import '../helpers/gdrive_api_client.dart';
import '../helpers/user_info.dart';
import '../model/user.dart';
import 'user_service.dart';

/// Layanan integrasi Google Sign-In & penyesuaian/sinkronisasi akun ke Database REST API.
class GoogleAuthService {
  final GDriveApiClient _apiClient = GDriveApiClient();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? (gdriveClientId.isNotEmpty ? gdriveClientId : null)
        : (androidClientId.isNotEmpty ? androidClientId : null),
    serverClientId: gdriveClientId.isNotEmpty ? gdriveClientId : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  /// Akun pengguna Google yang sedang login (jika ada).
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Memeriksa apakah saat ini sudah ada pengguna Google yang login.
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Menjalankan dialog login Google Sign-In langsung.
  Future<GoogleSignInAccount?> signIn() async {
    await _googleSignIn.signOut();
    return await _googleSignIn.signIn();
  }

  /// Melakukan proses logout / disconnect dari Google Sign-In.
  Future<void> signOut() async {
    try {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _apiClient.revokeToken(token);
        } catch (_) {}
      }
    } catch (_) {}
    await _googleSignIn.signOut();
  }

  /// Mengambil OAuth Access Token dari akun Google yang sedang aktif.
  Future<String?> getAccessToken() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.accessToken;
  }

  /// Mengambil data profil lengkap dari Google UserInfo REST API menggunakan [Dio].
  Future<Map<String, dynamic>?> getUserProfileFromApi() async {
    final token = await getAccessToken();
    if (token == null) return null;
    return await _apiClient.fetchGoogleUserInfo(token);
  }

  /// Login dengan Google, lalu cek/sinkronkan data akun ke Database REST API via [UserService].
  Future<bool> signInAndSyncDb() async {
    try {
      await _googleSignIn.signOut(); // Memaksa dialog pemilih akun Google (Account Chooser) selalu muncul
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // User membatalkan login

      final email = googleUser.email;
      final name = googleUser.displayName ?? email.split('@').first;
      final photoUrl = googleUser.photoUrl ?? '';

      final users = await UserService().listData();
      User? match = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => User(name: '', email: '', password: ''),
      );

      // Jika pengguna belum ada di Database, daftarkan (register) pengguna baru
      if (match.email.isEmpty) {
        final newUser = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          email: email,
          phone: '',
          password: '',           // Password kosong awal untuk Google user
          profileImage: photoUrl,
          role: email.trim().toLowerCase() == 'aviandanadhif25@gmail.com' ? 'admin' : 'user',
          balance: 0,
          googlelogin: 'google',  // Tandai sebagai Google user
        );
        match = await UserService().simpan(newUser);
      } else {
        if (email.trim().toLowerCase() == 'aviandanadhif25@gmail.com') {
          match.role = 'admin';
        }
        if (!match.isGoogleUser) {
          match.googlelogin = 'google';
          if (photoUrl.isNotEmpty && match.profileImage.isEmpty) {
            match.profileImage = photoUrl;
          }
        }
        await UserService().ubah(match, match.id);
      }

      // Simpan session pengguna ke UserInfo SharedPreferences
      await UserInfo().setToken("google_token_${match.email}");
      await UserInfo().setUserID(match.id.isNotEmpty ? match.id : match.email);
      await UserInfo().setUsername(match.name);
      await UserInfo().setEmail(match.email);
      await UserInfo().setRole(match.role);

      return true;
    } catch (e) {
      if (e is NetworkException ||
          e.toString().contains('NetworkException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw const NetworkException();
      }
      throw Exception('Gagal Login/Sync Google: $e');
    }
  }
}
