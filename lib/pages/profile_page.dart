import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/user_info.dart';
import '../model/user.dart';
import '../service/gdrive_service.dart';
import '../service/user_service.dart';

import '../widget/guest_login_placeholder.dart';
import '../utils/network_image_widget.dart';

/// Halaman Profil Pengguna yang menampilkan dan memperbarui informasi akun, foto profil (Drive/Gallery), serta sandi.
class ProfilePage extends StatefulWidget {
  /// Membuat instance [ProfilePage].
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// State pengelola update profil, upload foto ke Google Drive, dan penanganan akun Google pada [ProfilePage].
class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  String? _imagePath;
  User? currentUser;
  bool isLoading = true;
  bool isGuest = false;
  bool _obscurePassword = true;
  bool _isSaving = false; // ponytail: single guard for save button
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
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

      if (match != null) {
        currentUser = match;
        _nameController.text = match.name;
        _phoneController.text = match.phone;
        _passwordController.text = match.password;
        _imagePath = match.profileImage;
      }
      setState(() {
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

  Future<void> _pickImage() async {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Sumber Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1A469D)),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  try {
                    final bytes = await image.readAsBytes();
                    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
                      if (mounted) _showWarningDialog('Ukuran foto terlalu besar! Maksimal 2 MB.');
                      return;
                    }
                    _showSuccessDialog('Mengunggah profil...');
                    if (_imagePath != null && _imagePath!.contains('googleusercontent.com')) {
                      try { await GDriveService().deleteFile(_imagePath!); } catch (_) {}
                    }
                    try {
                      final driveUrl = await GDriveService().uploadFile(
                        bytes: bytes,
                        fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      );
                      if (driveUrl != null) {
                        setState(() => _imagePath = driveUrl);
                        if (mounted) _showSuccessDialog('Berhasil!');
                      } else {
                        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        setState(() => _imagePath = base64Str);
                        if (mounted) _showSuccessDialog('Foto berhasil digunakan!');
                      }
                    } catch (_) {
                      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      setState(() => _imagePath = base64Str);
                      if (mounted) _showSuccessDialog('Foto berhasil digunakan!');
                    }
                  } catch (e) {
                    if (mounted) _showWarningDialog('Gagal memproses gambar: $e');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Color(0xFF1A469D)),
              title: const Text('Input URL Gambar'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (urlCtx) => AlertDialog(
                    title: const Text('Input URL Gambar'),
                    content: TextField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: 'URL Gambar', hintText: 'https://...'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(urlCtx), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () {
                          if (urlController.text.trim().isNotEmpty) {
                            setState(() => _imagePath = urlController.text.trim());
                          }
                          Navigator.pop(urlCtx);
                        },
                        child: const Text('Gunakan'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                if (_imagePath != null && (_imagePath!.contains('drive.google.com') || _imagePath!.contains('googleusercontent.com'))) {
                  try {
                    await GDriveService().deleteFile(_imagePath!);
                  } catch (_) {}
                }
                setState(() => _imagePath = '');
              },
            ),
          ],
        ),
      ),
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

  void _saveProfile() async {
    if (_isSaving || currentUser == null) return;
    final isGoogle = currentUser!.isGoogleUser;
    if (_nameController.text.isEmpty || (!isGoogle && _passwordController.text.isEmpty)) {
      _showWarningDialog('Nama dan Password wajib diisi!');
      return;
    }
    if (_phoneController.text.trim().isNotEmpty && _phoneController.text.trim().length < 10) {
      _showWarningDialog('Nomor telepon minimal 10 digit');
      return;
    }
    if (!isGoogle && _passwordController.text.trim().length < 5) {
      _showWarningDialog('Password minimal 5 karakter');
      return;
    }

    bool isSame = currentUser!.name == _nameController.text &&
        currentUser!.phone == _phoneController.text &&
        currentUser!.password == _passwordController.text &&
        currentUser!.profileImage == (_imagePath ?? '');

    if (isSame) {
      _showWarningDialog('Tidak ada perubahan data yang dilakukan.');
      return;
    }

    setState(() => _isSaving = true);
    currentUser!.name = _nameController.text;
    currentUser!.phone = _phoneController.text;
    currentUser!.password = _passwordController.text;
    currentUser!.profileImage = _imagePath ?? '';

    try {
      if (currentUser!.id.isNotEmpty) {
        await UserService().ubah(currentUser!, currentUser!.id);
        await UserInfo().setUsername(currentUser!.name);
      }
      setState(() {});
      if (mounted) _showSuccessDialog('Profil berhasil diperbarui');
    } catch (e) {
      if (mounted) _showWarningDialog('Gagal memperbarui profil: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return const GuestLoginPlaceholder(
        title: 'Akun Saya',
        message: 'Silakan login terlebih dahulu untuk melihat dan mengelola profil Anda.',
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    final email = currentUser?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: SizedBox(
                      width: 130,
                      height: 130,
                      child: buildNetworkImage(
                        _imagePath ?? '',
                        width: 130,
                        height: 130,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(Icons.person, size: 65, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7D117),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          _buildTextField(_nameController, 'Nama Lengkap', Icons.person_outline),
          const SizedBox(height: 20),
          _buildTextField(_phoneController, 'No. Telepon', Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          _buildTextField(
            _passwordController,
            (currentUser?.isGoogleUser ?? false) ? 'Password (Opsional)' : 'Password',
            Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A469D),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false, TextInputType? keyboardType, Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A469D)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}
