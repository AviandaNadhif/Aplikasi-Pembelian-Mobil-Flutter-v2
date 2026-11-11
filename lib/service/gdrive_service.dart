import 'dart:convert';
import '../helpers/gdrive_api_client.dart';

/// Layanan integrasi Google Drive API untuk mengunggah, mengelola izin, dan menghapus file gambar.
/// Seluruh request HTTP dan konfigurasi API ditangani oleh [GDriveApiClient] berbasis [Dio].
class GDriveService {
  final GDriveApiClient _apiClient = GDriveApiClient();

  /// Mendapatkan OAuth Access Token via Refresh Token.
  Future<String?> getAccessToken() async {
    return await _apiClient.getAccessToken();
  }

  /// Helper internal untuk mencari atau membuat folder di Google Drive jika belum ada.
  Future<String?> _getOrCreateFolderId(String accessToken, [String folderName = 'mobile_programming']) async {
    try {
      final searchRes = await _apiClient.get(
        'files',
        queryParameters: {
          'q': "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        },
        token: accessToken,
      );

      if (searchRes.statusCode == 200) {
        final dynamic resData = searchRes.data;
        final Map<String, dynamic> data = resData is Map<String, dynamic>
            ? resData
            : Map<String, dynamic>.from(jsonDecode(resData.toString()));
        final List files = data['files'] ?? [];
        if (files.isNotEmpty) {
          return files.first['id'] as String;
        }
      }

      final createRes = await _apiClient.post(
        'files',
        {
          'name': folderName,
          'mimeType': 'application/vnd.google-apps.folder',
        },
        token: accessToken,
      );

      if (createRes.statusCode == 200 || createRes.statusCode == 201) {
        final dynamic resData = createRes.data;
        final Map<String, dynamic> data = resData is Map<String, dynamic>
            ? resData
            : Map<String, dynamic>.from(jsonDecode(resData.toString()));
        return data['id'] as String;
      }
    } catch (_) {}
    return null;
  }

  /// 1. Upload File ke Google Drive & Return Direct Public URL.
  Future<String?> uploadFile({
    required List<int> bytes,
    required String fileName,
    String mimeType = 'image/jpeg',
    String? token,
    String folderName = 'mobile_programming',
  }) async {
    final accessToken = token ?? await getAccessToken();
    if (accessToken == null) throw Exception('Google Auth Token tidak ditemukan');

    final folderId = await _getOrCreateFolderId(accessToken, folderName);
    final Map<String, dynamic> metadataMap = {
      'name': fileName,
      'mimeType': mimeType,
    };
    if (folderId != null) {
      metadataMap['parents'] = [folderId];
    }

    final response = await _apiClient.uploadMultipart(
      token: accessToken,
      bytes: bytes,
      fileName: fileName,
      metadataMap: metadataMap,
      mimeType: mimeType,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic resData = response.data;
      final Map<String, dynamic> jsonResponse = resData is Map<String, dynamic>
          ? resData
          : Map<String, dynamic>.from(jsonDecode(resData.toString()));
      final String fileId = jsonResponse['id'];
      return await createPublicUrl(fileId, token: accessToken);
    } else {
      throw Exception('Gagal Upload ke Drive: ${response.data}');
    }
  }

  /// 2. Set Izin File Jadi Publik (Reader: Anyone) & Ambil Public Direct URL.
  Future<String> createPublicUrl(String fileId, {String? token}) async {
    final accessToken = token ?? await getAccessToken();
    if (accessToken == null) throw Exception('Google Auth Token tidak ditemukan');

    await _apiClient.post(
      'files/$fileId/permissions',
      {'role': 'reader', 'type': 'anyone'},
      token: accessToken,
    );

    return 'https://lh3.googleusercontent.com/d/$fileId';
  }

  /// 3. Delete File dari Google Drive berdasarkan File ID atau Direct URL.
  Future<bool> deleteFile(String fileIdOrUrl, {String? token}) async {
    final accessToken = token ?? await getAccessToken();
    if (accessToken == null) throw Exception('Google Auth Token tidak ditemukan');

    String fileId = fileIdOrUrl;
    if (fileIdOrUrl.contains('id=')) {
      fileId = Uri.parse(fileIdOrUrl).queryParameters['id'] ?? fileIdOrUrl;
    } else if (fileIdOrUrl.contains('/d/')) {
      fileId = fileIdOrUrl.split('/d/').last.split('?').first;
    }

    final response = await _apiClient.delete(
      'files/$fileId',
      token: accessToken,
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }
}
