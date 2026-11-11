
import 'package:flutter/material.dart';
import '../helpers/api_client.dart';
import '../helpers/user_info.dart';
import '../model/car.dart';
import '../model/cart_item.dart';
import '../service/car_service.dart';
import '../service/cart_service.dart';
import '../utils/app_utils.dart';
import '../utils/network_image_widget.dart';
import 'login/login_page.dart';

/// Halaman Rincian Detail Mobil yang menampilkan gambar, spesifikasi, deskripsi, dan tombol Tambah ke Keranjang.
class CarDetailPage extends StatefulWidget {
  final Car car;

  /// Membuat instance [CarDetailPage] untuk menampilkan detail unit [car].
  const CarDetailPage({super.key, required this.car});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

/// State pengelola sinkronisasi data mobil dan aksi penambahan ke keranjang pada [CarDetailPage].
class _CarDetailPageState extends State<CarDetailPage> {
  late Car car;
  bool isLoading = true;
  bool _isAddingToCart = false; 

  @override
  void initState() {
    super.initState();
    car = widget.car;
    _refreshCar();
  }

  Future<void> _refreshCar() async {
    try {
      if (widget.car.id.isNotEmpty) {
        final updated = await CarService().getById(widget.car.id);
        setState(() {
          car = updated;
          isLoading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  Widget _displayImage(String imageStr, {BoxFit fit = BoxFit.cover}) {
    return buildNetworkImage(
      imageStr,
      fit: fit,
      errorWidget: const Icon(Icons.directions_car, size: 100, color: Color(0xFF1A469D)),
    );
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

  void _showSuccessDialog(String message) {
    _showAnimatedDialog(
      child: AlertDialog(
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
      ),
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

  Future<void> _addToCart() async {
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);
    try {
      final userId = await UserInfo().getUserID();
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF1A469D)),
                  SizedBox(width: 10),
                  Text('Akses Login'),
                ],
              ),
              content: const Text('Silahkan login terlebih dahulu untuk menambah ke keranjang / membeli mobil.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A469D)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                  },
                  child: const Text('Login', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        return;
      }

      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        carId: car.id,
        name: car.name,
        brand: car.brand,
        price: car.price,
        qty: 1,
        totalPrice: car.price,
        image: car.image,
      );

      await CartService().simpan(cartItem, maxStock: car.stock);
      if (mounted) _showSuccessDialog('Mobil berhasil ditambahkan ke keranjang');
    } catch (e) {
      if (mounted) {
        if (e is NetworkException) {
          AppUtils.showNoNetworkDialog(context, onRetry: _addToCart);
        } else {
          _showWarningDialog(e.toString().replaceAll('Exception: ', ''));
        }
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = car.stock <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF7D117),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                    ),
                    child: _displayImage(car.image, fit: BoxFit.contain),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                car.brand,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1A469D), fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              isOutOfStock ? 'Stok Habis' : 'Stok: ${car.stock}',
                              style: TextStyle(
                                color: isOutOfStock ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          car.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          car.type,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const Divider(height: 40),
                        const Text(
                          'Harga',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          AppUtils.formatRupiah(car.price),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Informasi Kendaraan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          car.description,
                          style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: (isOutOfStock || _isAddingToCart) ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A469D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  isOutOfStock ? 'Stok Habis' : 'Beli',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
