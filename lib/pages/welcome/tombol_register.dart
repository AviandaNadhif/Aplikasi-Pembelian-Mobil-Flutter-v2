import 'package:flutter/material.dart';
import '../register/register_page.dart';

/// Widget tombol yang mengarahkan pengguna ke halaman [RegisterPage].
class TombolRegister extends StatelessWidget {
  /// Membuat instance [TombolRegister].
  const TombolRegister({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Registrasi', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}
