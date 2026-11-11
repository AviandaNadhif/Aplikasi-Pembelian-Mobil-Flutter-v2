import 'dart:convert';
import 'package:flutter/material.dart';
import '../helpers/user_info.dart';
import '../model/car.dart';
import '../model/transaction.dart';
import '../service/car_service.dart';
import '../service/transaction_service.dart';
import '../widget/guest_login_placeholder.dart';

/// Halaman Koleksi Mobil Saya yang menampilkan daftar unit mobil yang berhasil dibeli oleh pengguna.
class CollectionPage extends StatefulWidget {
  /// Membuat instance [CollectionPage].
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

/// State pengelola ekstraksi item dari transaksi pengguna untuk ditampilkan di garasi koleksi pada [CollectionPage].
class _CollectionPageState extends State<CollectionPage> {
  List<Car> purchasedCars = [];
  bool isLoading = true;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
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
      final email = await UserInfo().getEmail() ?? '';
      final transactions = await TransactionService().listData();
      final allCars = await CarService().listData();

      final List<Transaction> userTransactions = transactions.where((tx) {
        if (userId.isNotEmpty && tx.userId == userId) return true;
        if (email.isNotEmpty && tx.buyerEmail.toLowerCase() == email.toLowerCase()) return true;
        return false;
      }).toList();

      List<Car> collection = [];
      for (var tx in userTransactions) {
        if (tx.itemsDetails.isNotEmpty) {
          final lines = tx.itemsDetails.split('\n');
          for (var line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;

            Car? match;
            for (var c in allCars) {
              if (trimmed.toLowerCase().contains(c.name.toLowerCase()) ||
                  c.name.toLowerCase().contains(trimmed.split('(').first.trim().toLowerCase())) {
                match = c;
                break;
              }
            }

            if (match != null) {
              collection.add(match);
            } else {
              final parts = trimmed.split('(');
              final carName = parts.first.trim();
              final brandName = parts.length > 1 ? parts[1].split(')').first.trim() : 'Mobil';
              collection.add(
                Car(
                  name: carName.isEmpty ? 'Mobil Pembelian' : carName,
                  price: 0,
                  brand: brandName,
                  type: 'Sedan',
                  image: '',
                  description: 'Telah Dibeli',
                  stock: 0,
                ),
              );
            }
          }
        }
      }

      setState(() {
        purchasedCars = collection;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Widget _displayImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D)),
      );
    } else if (path.startsWith('assets/img/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D)),
      );
    } else if (path.isNotEmpty) {
      try {
        final cleanBase64 = path.contains(',') ? path.split(',').last : path;
        return Image.memory(
          base64Decode(cleanBase64),
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D)),
        );
      } catch (e) {
        return const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D));
      }
    }
    return const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D));
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Koleksi Mobil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFFF7D117),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const GuestLoginPlaceholder(
          title: 'Koleksi Mobil Anda',
          message: 'Silahkan login terlebih dahulu untuk melihat garasi koleksi mobil Anda.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Koleksi Mobil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF7D117),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchasedCars.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_filled_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada mobil yang Anda beli', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: purchasedCars.length,
                  itemBuilder: (context, index) {
                    final car = purchasedCars[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: Colors.grey[50],
                              child: _displayImage(car.image),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Text(
                                  car.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(car.brand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Telah Dibeli',
                                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
