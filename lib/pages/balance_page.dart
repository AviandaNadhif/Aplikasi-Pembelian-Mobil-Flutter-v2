import 'package:flutter/material.dart';
import '../helpers/user_info.dart';
import '../model/user.dart';
import '../service/user_service.dart';
import '../utils/app_utils.dart';
import '../widget/guest_login_placeholder.dart';

/// Halaman Saldo Saya yang menampilkan saldo aktif, total pengeluaran, serta form Top Up Saldo.
class BalancePage extends StatefulWidget {
  /// Membuat instance [BalancePage].
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

/// State pengelola Top Up saldo dan sinkronisasi perubahan saldo ke server pada [BalancePage].
class _BalancePageState extends State<BalancePage> {
  final _amountController = TextEditingController();
  User? currentUser;
  bool isLoading = true;
  bool isGuest = false;
  bool _isSaving = false; 
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => isLoading = true);
    final userId = await UserInfo().getUserID();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() {
          isGuest = true;
          isLoading = false;
        });
      }
      return;
    }

    try {
      final email = await UserInfo().getEmail();
      final users = await UserService().listData();
      
      User? match;
      if (userId.isNotEmpty) {
        match = users.firstWhere(
          (u) => u.id == userId,
          orElse: () => users.firstWhere(
            (u) => u.email == email,
            orElse: () => User(id: userId, name: 'User', email: email ?? '', password: '', balance: 0),
          ),
        );
      }
      setState(() {
        currentUser = match;
        isGuest = false;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Berhasil'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFF1A469D), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }

  void _topUp() async {
    if (_isSaving || currentUser == null) return;
    int? amount = int.tryParse(_amountController.text.trim());
    if (amount != null && amount > 0) {
      setState(() => _isSaving = true);
      try {
        final updatedBalance = currentUser!.balance + amount;
        currentUser!.balance = updatedBalance;
        if (currentUser!.id.isNotEmpty) {
          await UserService().ubah(currentUser!, currentUser!.id);
        }
        setState(() {});
        _amountController.clear();
        if (mounted) _showSuccessDialog('Saldo berhasil ditambahkan');
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saldo Saya', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFF7D117),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const GuestLoginPlaceholder(
          title: 'Saldo Saya',
          message: 'Silahkan login terlebih dahulu untuk mengelola dan isi ulang saldo Anda.',
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saldo Saya', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFF7D117),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
                const SizedBox(height: 15),
                const Text('Gagal Terhubung ke Jaringan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () { setState(() => _error = null); _loadUser(); },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A469D), foregroundColor: Colors.white),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = currentUser ?? User(name: 'User', email: '', password: '', balance: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saldo Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF7D117),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A469D), Color(0xFF0D2D63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A469D).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                        const Icon(Icons.wallet, color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text('Total Saldo', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(
                      AppUtils.formatRupiah(user.balance),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Top Up Saldo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A469D))),
                  ),
                  hintText: 'Masukkan nominal top up',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _topUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A469D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Top Up Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saldo dapat digunakan untuk membeli mobil di katalog kami dengan mudah dan cepat.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
