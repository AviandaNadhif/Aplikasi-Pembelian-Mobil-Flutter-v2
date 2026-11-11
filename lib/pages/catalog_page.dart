import 'dart:convert';
import 'package:flutter/material.dart';
import '../helpers/api_client.dart';
import '../model/car.dart';
import '../model/cart_item.dart';
import '../service/car_service.dart';
import '../service/cart_service.dart';
import '../helpers/user_info.dart';
import '../utils/app_utils.dart';
import '../utils/network_image_widget.dart';
import 'car_detail_page.dart';
import 'login/login_page.dart';

/// Halaman Katalog Mobil yang menampilkan daftar filter merek, jenis, harga, serta pencarian unit.
class CatalogPage extends StatefulWidget {
  final String? initialBrand;
  final String? initialType;
  final String? initialSearch;
  final bool hideAppBar;

  /// Membuat instance [CatalogPage] dengan parameter opsional filter awal [initialBrand], [initialType], [initialSearch], dan [hideAppBar].
  const CatalogPage({
    super.key, 
    this.initialBrand, 
    this.initialType, 
    this.initialSearch,
    this.hideAppBar = false,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

/// State pengelola filtering, sorting, pencarian, dan penambahan ke keranjang pada [CatalogPage].
class _CatalogPageState extends State<CatalogPage> {
  String searchQuery = '';
  String? selectedBrand;
  String? selectedType;
  late TextEditingController _searchController;
  late Future<List<Car>> _carsFuture;

  List<String> brands = [];
  List<String> types = [];
  final Set<String> _savingCartIds = {}; 

  @override
  void initState() {
    super.initState();
    selectedBrand = widget.initialBrand;
    selectedType = widget.initialType;
    searchQuery = widget.initialSearch ?? '';
    _searchController = TextEditingController(text: searchQuery);
    _refreshCars();
  }

  void _refreshCars() {
    setState(() {
      _carsFuture = CarService().listData().then((carList) {
        final Set<String> brandSet = {};
        final Set<String> typeSet = {};
        for (var car in carList) {
          if (car.brand.isNotEmpty) brandSet.add(car.brand);
          if (car.type.isNotEmpty) typeSet.add(car.type);
          if (car.brandlist.isNotEmpty) {
            for (var b in car.brandlist.split(',')) {
              if (b.trim().isNotEmpty) brandSet.add(b.trim());
            }
          }
          if (car.typelist.isNotEmpty) {
            for (var t in car.typelist.split(',')) {
              if (t.trim().isNotEmpty) typeSet.add(t.trim());
            }
          }
        }
        if (brandSet.isEmpty) {
          brandSet.addAll(['Honda', 'BMW', 'Porsche', 'Mercedes', 'Toyota']);
        }
        if (typeSet.isEmpty) {
          typeSet.addAll(['Sports', 'Coupe', 'Sedan', 'SUV', 'MPV']);
        }
        if (mounted) {
          setState(() {
            brands = brandSet.toList();
            types = typeSet.toList();
          });
        }
        return carList;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(25),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Mobil',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            selectedBrand = null;
                            selectedType = null;
                          });
                          setState(() {
                            selectedBrand = null;
                            selectedType = null;
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Merk Mobil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildFilterChip(
                        label: 'Semua',
                        isSelected: selectedBrand == null,
                        onSelected: (_) {
                          setModalState(() => selectedBrand = null);
                          setState(() => selectedBrand = null);
                        },
                      ),
                      ...brands.map((brand) => _buildFilterChip(
                        label: brand,
                        isSelected: selectedBrand == brand,
                        onSelected: (_) {
                          setModalState(() => selectedBrand = brand);
                          setState(() => selectedBrand = brand);
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text('Jenis Mobil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildFilterChip(
                        label: 'Semua',
                        isSelected: selectedType == null,
                        onSelected: (_) {
                          setModalState(() => selectedType = null);
                          setState(() => selectedType = null);
                        },
                      ),
                      ...types.map((type) => _buildFilterChip(
                        label: type,
                        isSelected: selectedType == type,
                        onSelected: (_) {
                          setModalState(() => selectedType = type);
                          setState(() => selectedType = type);
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A469D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text('Tampilkan Hasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFFF7D117),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFFF7D117) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _displayImage(String imageStr, {BoxFit fit = BoxFit.cover}) {
    if (imageStr.startsWith('http')) {
      return buildNetworkImage(
        imageStr,
        fit: fit,
        errorWidget: const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D)),
      );
    } else if (imageStr.startsWith('assets/img/')) {
      return Image.asset(
        imageStr,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D)),
      );
    } else {
      try {
        return Image.memory(
          base64Decode(imageStr),
          fit: fit,
          errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D)),
        );
      } catch (e) {
        return const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A469D));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.hideAppBar ? null : AppBar(
        title: const Text('Katalog Mobil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF7D117),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<Car>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 15),
                    const Text(
                      'Gagal Terhubung ke Jaringan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}'.replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        _refreshCars();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A469D),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final catalog = snapshot.data ?? [];
          final filteredCars = catalog.where((car) {
            final matchesSearch = car.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                                  car.brand.toLowerCase().contains(searchQuery.toLowerCase()) ||
                                  car.type.toLowerCase().contains(searchQuery.toLowerCase());
            final matchesBrand = selectedBrand == null || car.brand == selectedBrand;
            final matchesType = selectedType == null || car.type == selectedType;
            return matchesSearch && matchesBrand && matchesType;
          }).toList();

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  top: widget.hideAppBar,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => searchQuery = value),
                              decoration: const InputDecoration(
                                hintText: 'Cari Mobil...',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Color(0xFF1A469D)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showFilterBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A469D),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.tune, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (filteredCars.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_filled_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Mobil tidak tersedia', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final car = filteredCars[index];
                        final bool isOutOfStock = car.stock <= 0;

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CarDetailPage(car: car)),
                            );
                            _refreshCars();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      SizedBox(width: double.infinity, child: _displayImage(car.image)),
                                      if (isOutOfStock)
                                        Container(color: Colors.black54, child: const Center(child: Text('STOK HABIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A469D)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(AppUtils.formatRupiah(car.price), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 13)),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 35,
                                        child: ElevatedButton(
                                           onPressed: (isOutOfStock || _savingCartIds.contains(car.id.isNotEmpty ? car.id : car.name)) ? null : () async {
                                            final cardId = car.id.isNotEmpty ? car.id : car.name;
                                            if (_savingCartIds.contains(cardId)) return;
                                            setState(() => _savingCartIds.add(cardId));
                                            try {
                                              final userId = await UserInfo().getUserID();
                                              if (userId == null || userId.isEmpty) {
                                                if (context.mounted) {
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
                                              if (context.mounted) {
                                                _showSuccessDialog('${car.name} ditambahkan ke keranjang');
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                if (e is NetworkException) {
                                                  AppUtils.showNoNetworkDialog(context);
                                                } else {
                                                  _showWarningDialog(e.toString().replaceAll('Exception: ', ''));
                                                }
                                              }
                                            } finally {
                                              if (mounted) setState(() => _savingCartIds.remove(cardId));
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1A469D),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text(isOutOfStock ? 'Habis' : 'Beli', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredCars.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
