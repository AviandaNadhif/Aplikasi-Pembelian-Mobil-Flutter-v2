import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Utility umum aplikasi untuk konversi gambar, format mata uang, dan dialog UI.
class AppUtils {
  /// Membaca file [XFile] dan mengonversinya menjadi string Base64.
  static Future<String> saveImage(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Memformat angka [price] menjadi format mata uang Rupiah Indonesia (contoh: "Rp 150.000.000").
  static String formatRupiah(int price) {
    String priceStr = price.toString();
    String result = '';
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      result = '${priceStr[i]}$result';
      count++;
      if (count == 3 && i > 0) {
        result = '.$result';
        count = 0;
      }
    }
    return 'Rp $result';
  }

  /// Menampilkan dialog penanganan error koneksi jaringan yang terputus.
  static void showNoNetworkDialog(BuildContext context, {VoidCallback? onRetry}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              SizedBox(width: 10),
              Text('Koneksi Terputus'),
            ],
          ),
          content: const Text(
            'Tidak dapat terkoneksi ke jaringan. Periksa sambungan internet Anda dan coba lagi.',
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry();
                },
                child: const Text('Coba Lagi', style: TextStyle(color: Color(0xFF1A469D), fontWeight: FontWeight.bold)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
