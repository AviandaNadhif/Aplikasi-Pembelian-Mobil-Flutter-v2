import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widget/sidebar.dart';
import 'beranda_page.dart';
import 'catalog_page.dart';
import 'cart_page.dart';
import 'struk_page.dart';
import 'profile_page.dart';

/// Halaman utama (Container utama) yang menampung Bottom Navigation Bar dan routing antar tab.
class HomePage extends StatefulWidget {
  /// Membuat instance [HomePage].
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State pengelola tab navigasi dan refresh data pada [HomePage].
class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _refreshCount = 0;
  
  String? _initialBrand;
  String? _initialType;
  String? _initialSearch;

  List<Widget> get _pages => [
    BerandaPage(
      key: ValueKey('beranda_$_refreshCount'),
      onNavigate: (index, {brand, type, search}) {
        setState(() {
          _selectedIndex = index;
          _initialBrand = brand;
          _initialType = type;
          _initialSearch = search;
          _refreshCount++;
        });
      },
    ),
    CatalogPage(
      key: ValueKey('catalog_${_refreshCount}_${_initialBrand}_${_initialType}_$_initialSearch'),
      hideAppBar: true,
      initialBrand: _initialBrand,
      initialType: _initialType,
      initialSearch: _initialSearch,
    ),
    CartPage(key: ValueKey('cart_$_refreshCount')),
    StrukPage(key: ValueKey('struk_$_refreshCount')),
    ProfilePage(key: ValueKey('profile_$_refreshCount')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _initialBrand = null;
        _initialType = null;
        _initialSearch = null;
      }
    });
  }

  void _refreshData() {
    setState(() {
      _refreshCount++;
    });
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? const Color(0xFF1A469D) : Colors.grey,
                size: 24,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1A469D) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Keluar Aplikasi?'),
              content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: _selectedIndex == 0 ? null : AppBar(
          title: Text(
            _selectedIndex == 1
                ? 'Katalog Mobil'
                : _selectedIndex == 2
                    ? 'Keranjang'
                    : _selectedIndex == 3
                        ? 'Riwayat Transaksi'
                        : 'Akun Saya',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFF7D117),
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        drawer: Sidebar(
          onNavigate: (index) => _onItemTapped(index),
          onRefresh: _refreshData,
        ),
        body: _pages[_selectedIndex],
        floatingActionButton: AnimatedScale(
          scale: _selectedIndex == 2 ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: FloatingActionButton(
            onPressed: () => _onItemTapped(2),
            backgroundColor: const Color(0xFFF7D117),
            shape: const CircleBorder(),
            elevation: 3,
            child: Icon(
              _selectedIndex == 2 ? Icons.shopping_bag : Icons.shopping_bag_outlined,
              color: const Color(0xFF1A469D),
              size: 24,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          padding: EdgeInsets.zero,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, Icons.home_outlined, 'Beranda'),
              _buildNavItem(1, Icons.grid_view_rounded, Icons.grid_view, 'Katalog'),
              const SizedBox(width: 70),
              _buildNavItem(3, Icons.receipt_long, Icons.receipt_long_outlined, 'Struk'),
              _buildNavItem(4, Icons.person, Icons.person_outline, 'Akun'),
            ],
          ),
        ),
      ),
    );
  }
}
