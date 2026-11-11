import 'dart:convert';
import 'package:flutter/material.dart';
import '../helpers/user_info.dart';
import '../model/car.dart';
import '../model/cart_item.dart';
import '../service/car_service.dart';
import '../service/cart_service.dart';
import '../utils/app_utils.dart';
import '../widget/guest_login_placeholder.dart';
import 'checkout_page.dart';

/// Halaman Keranjang Belanja yang mengelola daftar item belanja, pengubahan kuantitas, penghapusan, dan navigasi Checkout.
class CartPage extends StatefulWidget {
  /// Membuat instance [CartPage].
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

/// State pengelola item keranjang belanja dan sinkronisasi stok pada [CartPage].
class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];
  Map<String, Car> carMap = {};
  bool isLoading = true;
  bool isGuest = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
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
      final allItems = await CartService().listData();
      final userCart = allItems.where((item) => item.userId == userId).toList();

      final cars = await CarService().listData();
      final Map<String, Car> map = {};
      for (var c in cars) {
        map[c.id] = c;
      }

      setState(() {
        cartItems = userCart;
        carMap = map;
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

  Widget _displayImage(String imageStr, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (imageStr.startsWith('http')) {
      return Image.network(
        imageStr,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 30, color: Color(0xFF1A469D)),
      );
    } else if (imageStr.startsWith('assets/img/')) {
      return Image.asset(
        imageStr,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 30, color: Color(0xFF1A469D)),
      );
    } else {
      try {
        final cleanBase64 = imageStr.contains(',') ? imageStr.split(',').last : imageStr;
        return Image.memory(
          base64Decode(cleanBase64),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 30, color: Color(0xFF1A469D)),
        );
      } catch (e) {
        return const Icon(Icons.directions_car, size: 30, color: Color(0xFF1A469D));
      }
    }
  }

  void _showAnimatedDialog({required Widget child}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => child,
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }

  void _showWarningDialog(String message) {
    _showAnimatedDialog(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Peringatan'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF1A469D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _incrementQty(CartItem item) async {
    final car = carMap[item.carId];
    final maxStock = car?.stock ?? 999;
    if (item.qty + 1 > maxStock) {
      _showWarningDialog('Kuantitas di keranjang melebihi stok yang tersedia (Stok: $maxStock)');
      return;
    }

    item.qty += 1;
    item.totalPrice = item.price * item.qty;
    final itemId = item.id;
    if (itemId.isNotEmpty) {
      await CartService().ubah(item, itemId);
    }
    setState(() {});
  }

  Future<void> _decrementQty(CartItem item) async {
    if (item.qty > 1) {
      item.qty -= 1;
      item.totalPrice = item.price * item.qty;
      final itemId = item.id;
      if (itemId.isNotEmpty) {
        await CartService().ubah(item, itemId);
      }
      setState(() {});
    } else {
      await _removeItem(item);
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final itemId = item.id;
    if (itemId.isNotEmpty) {
      await CartService().hapus(item);
    }
    await _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return const GuestLoginPlaceholder(
        title: 'Keranjang Belanja',
        message: 'Silahkan login terlebih dahulu untuk melihat dan mengelola keranjang Anda.',
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
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
                  onPressed: () { setState(() => _error = null); _loadCart(); },
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

    final total = cartItems.fold(0, (sum, item) => sum + (item.price * item.qty));

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: cartItems.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Keranjang Anda masih kosong', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(15),
                          itemCount: cartItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            final carStock = carMap[item.carId]?.stock ?? 0;
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
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _displayImage(item.image),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A469D), fontSize: 16),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(item.brand, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppUtils.formatRupiah(item.price * item.qty),
                                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                                          ),
                                          if (carStock > 0)
                                            Text(
                                              'Stok tersedia: $carStock',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _decrementQty(item),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.remove, size: 16, color: Colors.black),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '${item.qty}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _incrementQty(item),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1A469D),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.add, size: 16, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () => _removeItem(item),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (cartItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontSize: 15, color: Colors.grey)),
                            Text(
                              AppUtils.formatRupiah(total),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    cartItems: cartItems,
                                    totalPrice: total,
                                  ),
                                ),
                              );

                              if (result == true) {
                                _loadCart();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A469D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Checkout Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
    );
  }
}
