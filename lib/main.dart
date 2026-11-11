import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/welcome/welcome_page.dart';

/// Titik masuk (entry point) utama aplikasi Beli Mobil.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

/// Root widget aplikasi Flutter yang mengonfigurasi tema dan halaman awal.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beli Mobil',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1A469D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A469D),
          primary: const Color(0xFF1A469D),
          secondary: const Color(0xFFF7D117),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7D117),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
