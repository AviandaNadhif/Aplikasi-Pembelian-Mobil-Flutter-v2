import 'package:dio/dio.dart';
import '../helpers/api_client.dart';
import '../model/user.dart';

/// Layanan service untuk pengelolaan data pengguna (User) via REST API.
class UserService {
  /// Mengambil daftar seluruh pengguna dari server API.
  Future<List<User>> listData() async {
    final Response response = await ApiClient().get('users');
    final List data = response.data as List;
    List<User> result = data.map((json) => User.fromJson(Map<String, dynamic>.from(json))).toList();
    return result;
  }

  /// Menyimpan akun [user] baru ke server API.
  Future<User> simpan(User user) async {
    user.id = DateTime.now().millisecondsSinceEpoch.toString();
    var data = user.toJson();
    final Response response = await ApiClient().post('users', data);
    User result = User.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Memperbarui data pengguna [user] berdasarkan [id].
  Future<User> ubah(User user, String id) async {
    var data = user.toJson();
    final Response response = await ApiClient().put('users/$id', data);
    User result = User.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Mengambil detail satu pengguna berdasarkan [id].
  Future<User> getById(String id) async {
    final Response response = await ApiClient().get('users/$id');
    User result = User.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Menghapus data akun [user] dari server API.
  Future<User> hapus(User user) async {
    final Response response = await ApiClient().delete('users/${user.id}');
    User result = User.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }
}

