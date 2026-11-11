import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

// Kredensial Google OAuth & Drive dari .env
final String gdriveClientId = dotenv.env['GDRIVE_CLIENT_ID'] ?? '';
final String gdriveClientSecret = dotenv.env['GDRIVE_CLIENT_SECRET'] ?? '';
final String gdriveRefreshToken = dotenv.env['GDRIVE_REFRESH_TOKEN'] ?? '';
final String androidClientId = dotenv.env['ANDROID_CLIENT_ID'] ?? '';

// Base URLs untuk Google Drive API dan Google OAuth 2.0
const String gdriveApiBaseUrl = 'https://www.googleapis.com/drive/v3/';
const String gdriveUploadBaseUrl = 'https://www.googleapis.com/upload/drive/v3/';
const String googleOAuthTokenUrl = 'https://oauth2.googleapis.com/token';
const String googleUserInfoUrl = 'https://www.googleapis.com/oauth2/v3/userinfo';
const String googleRevokeTokenUrl = 'https://oauth2.googleapis.com/revoke';

final Dio dioGDrive = Dio(BaseOptions(
  baseUrl: gdriveApiBaseUrl,
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
));

final Dio dioGDriveUpload = Dio(BaseOptions(
  baseUrl: gdriveUploadBaseUrl,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
));

final Dio dioGoogleAuth = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
));

/// Client HTTP berbasis [Dio] untuk menangani komunikasi REST API ke Google Drive API & Google Auth.
class GDriveApiClient {
  /// Membersihkan leading slash pada path endpoint agar konsisten.
  String _formatPath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// Memeriksa apakah [DioException] disebabkan oleh masalah koneksi / timeout jaringan.
  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  // ==========================================
  // GOOGLE AUTH & OAUTH ENDPOINTS
  // ==========================================

  /// Request token OAuth Google (Refresh Token flow) via x-www-form-urlencoded.
  Future<Response> postToken(Map<String, dynamic> data) async {
    try {
      final response = await dioGoogleAuth.post(
        googleOAuthTokenUrl,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return response;
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error POST token request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Mendapatkan Access Token OAuth Google menggunakan kredensial Refresh Token dari .env.
  Future<String?> getAccessToken() async {
    if (gdriveRefreshToken.isEmpty) {
      throw Exception('GDRIVE_REFRESH_TOKEN tidak ditemukan di file .env');
    }

    try {
      final response = await postToken({
        'client_id': gdriveClientId,
        'client_secret': gdriveClientSecret,
        'refresh_token': gdriveRefreshToken,
        'grant_type': 'refresh_token',
      });

      if (response.statusCode == 200) {
        final dynamic resData = response.data;
        final Map<String, dynamic> data = resData is Map<String, dynamic>
            ? resData
            : Map<String, dynamic>.from(jsonDecode(resData.toString()));
        return data['access_token'] as String?;
      } else {
        throw Exception('Gagal mendapatkan Access Token (${response.statusCode}): ${response.data}');
      }
    } catch (e) {
      throw Exception('Error OAuth Token Refresh: $e');
    }
  }

  /// Mengambil data profil user dari Google UserInfo REST API menggunakan [accessToken].
  Future<Map<String, dynamic>> fetchGoogleUserInfo(String accessToken) async {
    try {
      final response = await dioGoogleAuth.get(
        googleUserInfoUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      final dynamic resData = response.data;
      return resData is Map<String, dynamic>
          ? resData
          : Map<String, dynamic>.from(jsonDecode(resData.toString()));
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error UserInfo request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Mencabut (revoke) token autentikasi Google.
  Future<Response> revokeToken(String token) async {
    try {
      final response = await dioGoogleAuth.post(
        '$googleRevokeTokenUrl?token=$token',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return response;
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error Revoke Token request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }

  // ==========================================
  // GOOGLE DRIVE API ENDPOINTS
  // ==========================================

  /// Mengirim HTTP GET request ke endpoint Google Drive API [path].
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    try {
      final formattedPath = _formatPath(path);
      final response = await dioGDrive.get(
        formattedPath,
        queryParameters: queryParameters,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      return response;
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error GET request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Mengirim HTTP POST request ke endpoint Google Drive API [path].
  Future<Response> post(
    String path,
    dynamic data, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    try {
      final formattedPath = _formatPath(path);
      final response = await dioGDrive.post(
        formattedPath,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error POST request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Mengirim HTTP DELETE request ke endpoint Google Drive API [path].
  Future<Response> delete(
    String path, {
    String? token,
  }) async {
    try {
      final formattedPath = _formatPath(path);
      final response = await dioGDrive.delete(
        formattedPath,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      return response;
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error DELETE request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Mengunggah file multipart ke Google Drive menggunakan [Dio] [FormData].
  Future<Response> uploadMultipart({
    required String token,
    required List<int> bytes,
    required String fileName,
    required Map<String, dynamic> metadataMap,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      DioMediaType? fileMediaType;
      try {
        fileMediaType = DioMediaType.parse(mimeType);
      } catch (_) {
        fileMediaType = DioMediaType('image', 'jpeg');
      }

      final formData = FormData.fromMap({
        'metadata': MultipartFile.fromString(
          jsonEncode(metadataMap),
          contentType: DioMediaType('application', 'json'),
        ),
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: fileMediaType,
        ),
      });

      final response = await dioGDriveUpload.post(
        'files?uploadType=multipart',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error Upload Multipart request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }
}
