import 'package:flutter/material.dart';
import '../pages/welcome/welcome_page.dart';

/// Widget tampilan placeholder saat pengguna bertindak sebagai Guest (belum login).
class GuestLoginPlaceholder extends StatelessWidget {
  final String title;
  final String message;

  /// Membuat [GuestLoginPlaceholder] dengan [title] dan [message] opsi.
  const GuestLoginPlaceholder({
    super.key,
    required this.title,
    this.message = 'Silakan login terlebih dahulu untuk mengakses fitur ini.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 64, color: Color(0xFF1A469D)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WelcomePage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A469D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Login Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
