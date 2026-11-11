import 'dart:convert';
import 'package:flutter/material.dart';
import '../helpers/user_info.dart';
import '../model/user.dart';
import '../service/user_service.dart';
import '../pages/welcome/welcome_page.dart';
import '../pages/collection_page.dart';
import '../utils/network_image_widget.dart';

import '../pages/balance_page.dart';
import '../pages/admin_page.dart';

/// Widget navigasi samping (Navigation Drawer) aplikasi.
class Sidebar extends StatefulWidget {
  final Function(int)? onNavigate;
  final VoidCallback? onRefresh;

  /// Membuat [Sidebar] dengan callback navigasi [onNavigate] dan refresh [onRefresh].
  const Sidebar({super.key, this.onNavigate, this.onRefresh});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _username = 'Guest';
  String _userEmail = '';
  String _userRole = 'user';
  String _profileImage = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userId = await UserInfo().getUserID();
    String? name = await UserInfo().getUsername();
    String? email = await UserInfo().getEmail();
    String? role = await UserInfo().getRole();

    if (userId != null && userId.isNotEmpty) {
      try {
        final User user = await UserService().getById(userId);
        if (mounted) {
          setState(() {
            _username = user.name.isNotEmpty ? user.name : (name ?? 'Guest');
            _userEmail = user.email.isNotEmpty ? user.email : (email ?? '');
            _userRole = user.role.isNotEmpty ? user.role : (role ?? 'user');
            _profileImage = user.profileImage;
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _username = name ?? 'Guest';
        _userEmail = email ?? '';
        _userRole = role ?? 'user';
      });
    }
  }

  Widget _buildAvatar() {
    if (_profileImage.startsWith('http')) {
      return CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: buildNetworkImage(
            _profileImage,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorWidget: const Icon(Icons.person, size: 40, color: Color(0xFF1A469D)),
          ),
        ),
      );
    } else if (_profileImage.isNotEmpty) {
      try {
        final cleanBase64 = _profileImage.contains(',') ? _profileImage.split(',').last : _profileImage;
        return CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Image.memory(
              base64Decode(cleanBase64),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.person, size: 40, color: Color(0xFF1A469D)),
            ),
          ),
        );
      } catch (_) {}
    }
    return const CircleAvatar(
      radius: 35,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, size: 40, color: Color(0xFF1A469D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _userRole.toLowerCase() == 'admin';

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Row(
                    children: [
                      Text(
                        _username,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.redAccent : Colors.blueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _userRole.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  accountEmail: Text(
                    _userEmail.isNotEmpty ? _userEmail : _username,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  currentAccountPicture: _buildAvatar(),
                  decoration: const BoxDecoration(color: Color(0xFFF7D117)),
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: Color(0xFF1A469D)),
                  title: const Text('Beranda'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onNavigate != null) widget.onNavigate!(0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF1A469D)),
                  title: const Text('Katalog Mobil'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onNavigate != null) widget.onNavigate!(1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Color(0xFF1A469D)),
                  title: const Text('Keranjang'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onNavigate != null) widget.onNavigate!(2);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.library_books, color: Color(0xFF1A469D)),
                  title: const Text('Koleksi Mobil'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CollectionPage()));
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF1A469D)),
                  title: const Text('Saldo Saya'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const BalancePage())
                    ).then((_) {
                      if (widget.onRefresh != null) widget.onRefresh!();
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Color(0xFF1A469D)),
                  title: const Text('Struk'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onNavigate != null) widget.onNavigate!(3);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF1A469D)),
                  title: const Text('Akun Saya'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onNavigate != null) widget.onNavigate!(4);
                  },
                ),
                if (isAdmin) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize, color: Color(0xFF1A469D)),
                    title: const Text('Dashboard Admin'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const AdminPage())
                      ).then((_) {
                        if (widget.onRefresh != null) widget.onRefresh!();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          if (_userEmail.isEmpty || _username == 'Guest')
            ListTile(
              leading: const Icon(Icons.login, color: Color(0xFF1A469D)),
              title: const Text('Login / Masuk', style: TextStyle(color: Color(0xFF1A469D), fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WelcomePage()));
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await UserInfo().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (route) => false,
                  );
                }
              },
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
