import 'package:flutter/material.dart';
import '../service/car_service.dart';
import 'admin_page.dart';
import 'catalog_page.dart';
import 'collection_page.dart';


/// Halaman Beranda (Home Dashboard) yang menampilkan pencarian, menu cepat, jenis & merek mobil.
class BerandaPage extends StatefulWidget {
  final Function(int, {String? brand, String? type, String? search})? onNavigate;

  /// Membuat instance [BerandaPage] dengan callback navigasi [onNavigate].
  const BerandaPage({super.key, this.onNavigate});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

/// State pengelola pencarian dan filter cepat merek & jenis mobil pada [BerandaPage].
class _BerandaPageState extends State<BerandaPage> {
  bool isAdmin = false;
  final TextEditingController _searchController = TextEditingController();

  List<String> brands = [];
  List<String> types = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final cars = await CarService().listData();
      final Set<String> brandSet = {};
      final Set<String> typeSet = {};
      for (var car in cars) {
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
    } catch (_) {
      if (mounted) {
        setState(() {
          brands = ['Honda', 'BMW', 'Porsche', 'Mercedes', 'Toyota'];
          types = ['Sports', 'Coupe', 'Sedan', 'SUV', 'MPV'];
        });
      }
    }
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    if (widget.onNavigate != null) {
      widget.onNavigate!(1, search: query);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CatalogPage(initialSearch: query),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7D117),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            "AutoODGJ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1A469D),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _search,
                          decoration: InputDecoration(
                            hintText: 'Cari Merek, Model atau Kata Kunci',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.black87),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward, color: Color(0xFF1A469D)),
                              onPressed: () => _search(_searchController.text),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickMenuItem(
                  icon: Icons.directions_car_filled_rounded,
                  label: 'Beli Mobil',
                  onTap: () {
                    if (widget.onNavigate != null) {
                      widget.onNavigate!(1);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogPage()));
                    }
                  },
                ),
                const SizedBox(width: 25),
                _buildQuickMenuItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Keranjang',
                  onTap: () {
                    if (widget.onNavigate != null) widget.onNavigate!(2);
                  },
                ),
                const SizedBox(width: 25),
                _buildQuickMenuItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Riwayat',
                  onTap: () {
                    if (widget.onNavigate != null) widget.onNavigate!(3);
                  },
                ),
                const SizedBox(width: 25),
                _buildQuickMenuItem(
                  icon: Icons.person_rounded,
                  label: 'Akun Saya',
                  onTap: () {
                    if (widget.onNavigate != null) widget.onNavigate!(4);
                  },
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 25),
                  _buildQuickMenuItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage()));
                    },
                  ),
                ],
              ],
            ),
          ),



          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Koleksi Mobil Anda',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CollectionPage()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF1A469D).withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7D117),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.library_books, color: Color(0xFF1A469D)),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Lihat koleksi mobil yang telah Anda beli dan kelola garasi impian Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jenis Mobil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                ),
                TextButton(
                  onPressed: () {
                    if (widget.onNavigate != null) {
                      widget.onNavigate!(1);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogPage()));
                    }
                  },
                  child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF1A469D))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: types.length,
              itemBuilder: (context, index) {
                return _buildTypeCard(types[index]);
              },
            ),
          ),

          const SizedBox(height: 30),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Merk Mobil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                return _buildBrandIcon(brands[index]);
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF7D117).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF7D117).withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: const Color(0xFF1A469D), size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A469D)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(String typeName) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(1, type: typeName);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatalogPage(initialType: typeName),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF1A469D).withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(
            typeName,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandIcon(String brandName) {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!(1, brand: brandName);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatalogPage(initialBrand: brandName),
            ),
          );
        }
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1A469D).withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  brandName.isNotEmpty ? brandName.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A469D)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              brandName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A469D)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
