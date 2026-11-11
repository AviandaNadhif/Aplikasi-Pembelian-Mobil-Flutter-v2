import 'package:flutter/material.dart';
import '../login/login_page.dart';

/// Widget tombol yang mengarahkan pengguna ke halaman [LoginPage].
class TombolLogin extends StatelessWidget {
  /// Membuat instance [TombolLogin].
  const TombolLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Login', style: TextStyle(color: Colors.blue, fontSize: 18)),
      ),
    );
  }
}
