import 'package:flutter/material.dart';
import '../../helpers/user_info.dart';
import '../home_page.dart';
import '../login/login_page.dart';
import '../register/register_page.dart';

/// Halaman sambutan (Landing Screen) aplikasi tempat memilih opsi Login, Registrasi, atau Masuk sebagai Tamu.
class WelcomePage extends StatelessWidget {
  /// Membuat instance [WelcomePage].
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/welcome.png',
                    height: 240,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.car_rental_sharp, size: 160, color: Color(0xFF1A469D)),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A469D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selamat datang di aplikasi pembelian mobil ODGJ. Temukan mobil impian Anda dengan harga terbaik. Dijamin Sekali beli langsung beli mobil baru lagi!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7D117),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A469D)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Registrasi', style: TextStyle(color: Color(0xFF1A469D), fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton.icon(
                    onPressed: () async {
                      await UserInfo().logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_outline, color: Color(0xFF1A469D)),
                    label: const Text(
                      'Masuk sebagai Tamu (Lihat Mobil)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF1A469D), fontSize: 16, fontWeight: FontWeight.w600, ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
