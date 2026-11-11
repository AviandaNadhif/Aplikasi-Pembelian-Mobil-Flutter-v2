import 'dart:convert';
import 'package:flutter/material.dart';
import '../helpers/api_client.dart';
import '../helpers/user_info.dart';
import '../model/car.dart';
import '../model/cart_item.dart';
import '../model/transaction.dart';
import '../service/car_service.dart';
import '../service/cart_service.dart';
import '../service/transaction_service.dart';
import '../service/user_service.dart';
import '../utils/app_utils.dart';


/// Halaman Checkout Pembelian yang memverifikasi saldo, memotong stok mobil, dan menghasilkan transaksi resi baru.
class CheckoutPage extends StatefulWidget {
  final List<CartItem>? cartItems;
  final int? totalPrice;

  /// Membuat instance [CheckoutPage] dengan daftar [cartItems] dan total harga [totalPrice].
  const CheckoutPage({
    super.key,
    this.cartItems,
    this.totalPrice,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

/// State pengelola proses pemotongan saldo, pengurangan stok unit, dan pembuatan transaksi pada [CheckoutPage].
class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;
  int _userBalance = 0;
  bool _isLoadingUser = true;
  List<CartItem> _items = [];

  @override
  void initState() {
    super.initState();
    _initCheckoutData();
  }

  Future<void> _initCheckoutData() async {
    setState(() => _isLoadingUser = true);
    final userId = await UserInfo().getUserID();

    try {
      if (userId != null && userId.isNotEmpty) {
        final user = await UserService().getById(userId);
        _userBalance = user.balance;
      }
    } catch (_) {}

    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      _items = List.from(widget.cartItems!);
    } else {
      try {
        final cartList = await CartService().listData();
        if (userId != null && userId.isNotEmpty) {
          final userCart = cartList.where((i) => i.userId == userId).toList();
          _items = userCart.isNotEmpty ? userCart : cartList;
        } else {
          _items = cartList;
        }
      } catch (_) {
        _items = [];
      }
    }

    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  Widget _displayImage(String imageStr, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (imageStr.startsWith('http')) {
      return Image.network(
        imageStr,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 40, color: Color(0xFF1A469D)),
      );
    } else if (imageStr.startsWith('assets/img/')) {
      return Image.asset(
        imageStr,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 40, color: Color(0xFF1A469D)),
      );
    } else {
      try {
        return Image.memory(
          base64Decode(imageStr.contains(',') ? imageStr.split(',').last : imageStr),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 40, color: Color(0xFF1A469D)),
        );
      } catch (e) {
        return const Icon(Icons.directions_car, size: 40, color: Color(0xFF1A469D));
      }
    }
  }

  void _showSuccessDialog(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
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
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
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

  Future<void> _processCheckout() async {
    if (_items.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final userId = await UserInfo().getUserID();
      final buyerName = await UserInfo().getUsername() ?? 'Pembeli';
      final buyerEmail = await UserInfo().getEmail() ?? 'user@gmail.com';
      final resiCode = 'RESI-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final totalItem = _items.fold<int>(0, (sum, i) => sum + i.qty);
      final grandTotal = widget.totalPrice ?? _items.fold<int>(0, (sum, i) => sum + (i.totalPrice > 0 ? i.totalPrice : (i.price * i.qty)));
      final itemsDetails = _items.map((i) => "${i.name} (${i.brand}) - Qty: ${i.qty}").join('\n');

      // 1. Kurangi saldo user
      if (userId != null && userId.isNotEmpty) {
        try {
          final user = await UserService().getById(userId);
          if (user.id.isNotEmpty) {
            user.balance = (user.balance - grandTotal) < 0 ? 0 : (user.balance - grandTotal);
            user.spent = user.spent + grandTotal;
            await UserService().ubah(user, user.id);
          }
        } catch (_) {}
      }

      // 1.5. Kurangi stok mobil
      try {
        final allCars = await CarService().listData();
        for (var item in _items) {
          Car? targetCar;
          if (item.carId.isNotEmpty) {
            targetCar = allCars.firstWhere(
              (c) => c.id == item.carId,
              orElse: () => Car(id: '', name: '', price: 0, brand: '', type: '', image: '', description: '', stock: 0),
            );
          }
          if (targetCar == null || targetCar.id.isEmpty) {
            targetCar = allCars.firstWhere(
              (c) => c.name.toLowerCase() == item.name.toLowerCase(),
              orElse: () => Car(id: '', name: '', price: 0, brand: '', type: '', image: '', description: '', stock: 0),
            );
          }

          if (targetCar.id.isNotEmpty) {
            final newStock = (targetCar.stock - item.qty) < 0 ? 0 : (targetCar.stock - item.qty);
            targetCar.stock = newStock;
            await CarService().ubah(targetCar, targetCar.id);
          }
        }
      } catch (_) {}

      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId ?? '',
        resi: resiCode,
        buyerName: buyerName,
        buyerEmail: buyerEmail,
        totalItem: totalItem > 0 ? totalItem : 1,
        totalPrice: grandTotal,
        date: todayStr,
        itemsDetails: itemsDetails,
      );

      // 2. Simpan transaksi ke MockAPI
      await TransactionService().simpan(newTransaction);

      // 3. Kosongkan keranjang untuk user ini
      await CartService().clearCart(userId);

      setState(() => _isProcessing = false);
      if (mounted) {
        _showSuccessDialog('Pembelian Berhasil! Transaksi telah disimpan.');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        if (e is NetworkException) {
          AppUtils.showNoNetworkDialog(context, onRetry: _processCheckout);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memproses transaksi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.totalPrice ?? _items.fold<int>(0, (sum, i) => sum + (i.totalPrice > 0 ? i.totalPrice : (i.price * i.qty)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF7D117),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Text('Tidak ada item untuk dibeli', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final itemTotal = item.totalPrice > 0 ? item.totalPrice : (item.price * item.qty);
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _displayImage(item.image),
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A469D))),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.brand} (Qty: ${item.qty})',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppUtils.formatRupiah(itemTotal),
                                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Pembayaran',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saldo Saat Ini', style: TextStyle(color: Colors.grey)),
                          Text(
                            AppUtils.formatRupiah(_userBalance),
                            style: TextStyle(
                              color: _userBalance >= grandTotal ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembelian', style: TextStyle(color: Colors.grey)),
                          Text(AppUtils.formatRupiah(grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sisa Saldo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            AppUtils.formatRupiah(_userBalance - grandTotal),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isProcessing || _userBalance < grandTotal || _items.isEmpty)
                              ? null
                              : _processCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A469D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Konfirmasi',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      if (_userBalance < grandTotal && _items.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: Center(
                            child: Text(
                              'Peringatan: Saldo tidak mencukupi untuk melakukan transaksi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
