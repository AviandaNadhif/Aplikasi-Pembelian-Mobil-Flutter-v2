import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Base URL 1: Menyimpan 'cars' dan 'users'
final String baseUrlPrimary = dotenv.env['BASE_URL_PRIMARY'] ?? '';

// Base URL 2: Menyimpan 'transactions'
final String baseUrlTransaction = dotenv.env['BASE_URL_TRANSACTION'] ?? '';

/// Thrown when the device cannot reach MockAPI (no internet / timeout).
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Tidak dapat terkoneksi ke jaringan.']);
  @override
  String toString() => message;
}

final Dio dioPrimary = Dio(BaseOptions(
  baseUrl: baseUrlPrimary,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

final Dio dioTransaction = Dio(BaseOptions(
  baseUrl: baseUrlTransaction,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

/// Client HTTP berbasis Dio untuk menangani komunikasi REST API ke MockAPI.
class ApiClient {
  /// Membersihkan leading slash pada path endpoint agar konsisten.
  String _formatPath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// Menentukan instance [Dio] yang digunakan berdasarkan endpoint (Primary / Transaction).
  Dio _selectDio(String path) {
    final cleanPath = _formatPath(path);
    if (cleanPath.startsWith('transactions') || cleanPath.startsWith('carts')) {
      return dioTransaction;
    }
    return dioPrimary;
  }

  /// Memeriksa apakah [DioException] disebabkan oleh masalah koneksi / timeout jaringan.
  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  /// Mengirim HTTP GET request ke endpoint [path].
  Future<Response> get(String path) async {
    try {
      final formattedPath = _formatPath(path);
      final response = await _selectDio(formattedPath).get(formattedPath);
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

  /// Mengirim HTTP POST request ke endpoint [path] membawa payload [data].
  Future<Response> post(String path, dynamic data) async {
    try {
      final formattedPath = _formatPath(path);
      final payload = (data is Map<String, dynamic>)
          ? <String, dynamic>{'id': data['id'] ?? '', ...data}
          : data;
      final response = await _selectDio(formattedPath).post(formattedPath, data: payload);
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

  /// Mengirim HTTP PUT request ke endpoint [path] memperbarui data dengan payload [data].
  Future<Response> put(String path, dynamic data) async {
    try {
      final formattedPath = _formatPath(path);
      final payload = (data is Map<String, dynamic>)
          ? <String, dynamic>{'id': data['id'] ?? '', ...data}
          : data;
      final response = await _selectDio(formattedPath).put(formattedPath, data: payload);
      return response;
    } on DioException catch (e) {
      if (_isNetworkError(e)) throw const NetworkException();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Error PUT request';
      throw Exception(msg);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Mengirim HTTP DELETE request ke endpoint [path].
  Future<Response> delete(String path) async {
    try {
      final formattedPath = _formatPath(path);
      final response = await _selectDio(formattedPath).delete(formattedPath);
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
}
