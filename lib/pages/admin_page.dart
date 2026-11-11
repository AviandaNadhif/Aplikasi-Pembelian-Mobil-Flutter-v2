import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/api_client.dart';
import '../model/car.dart';
import '../model/user.dart';
import '../service/car_service.dart';
import '../service/gdrive_service.dart';
import '../service/user_service.dart';
import '../utils/app_utils.dart';
import '../utils/network_image_widget.dart';

/// Halaman Dashboard Admin untuk kelola data mobil (Tambah/Edit/Hapus) dan manajemen akun pengguna & saldo.
class AdminPage extends StatefulWidget {
  /// Membuat instance [AdminPage].
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

/// State pengelola manajemen mobil, upload gambar Google Drive, dan penyuntingan saldo user pada [AdminPage].
class _AdminPageState extends State<AdminPage> {
  // Car Form Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedBrand;
  String? _selectedType;
  String? _base64Image;
  Car? _editingCar;

  // User Form Controllers
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _userPhoneController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _userBalanceController = TextEditingController();
  String _selectedRole = 'user';
  User? _editingUser;

  List<Car> _cars = [];
  List<User> _users = [];
  List<String> _brands = [];
  List<String> _types = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final cars = await CarService().listData();
      final users = await UserService().listData();

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
        brandSet.addAll(['Honda', 'BMW', 'Porsche', 'Mercedes', 'Toyota', 'Tesla']);
      }
      if (typeSet.isEmpty) {
        typeSet.addAll(['Sports', 'Coupe', 'Sedan', 'SUV', 'MPV', 'Electric']);
      }

      if (mounted) {
        setState(() {
          _cars = cars;
          _users = users;
          _brands = brandSet.toList();
          _types = typeSet.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showAnimatedDialog({required Widget child, bool barrierDismissible = true}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
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

  Future<void> _pickImage(StateSetter setDialogState) async {
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
                    _showSuccessDialog('Mengunggah gambar...');
                    if (_base64Image != null && _base64Image!.contains('googleusercontent.com')) {
                      try { await GDriveService().deleteFile(_base64Image!); } catch (_) {}
                    }
                    try {
                      final driveUrl = await GDriveService().uploadFile(
                        bytes: bytes,
                        fileName: 'car_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      );
                      if (driveUrl != null) {
                        setDialogState(() => _base64Image = driveUrl);
                        if (mounted) _showSuccessDialog('Berhasil!');
                      } else {
                        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        setDialogState(() => _base64Image = base64Str);
                        if (mounted) _showSuccessDialog('Foto berhasil digunakan!');
                      }
                    } catch (_) {
                      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      setDialogState(() => _base64Image = base64Str);
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
                            setDialogState(() => _base64Image = urlController.text.trim());
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
                if (_base64Image != null && (_base64Image!.contains('drive.google.com') || _base64Image!.contains('googleusercontent.com'))) {
                  try {
                    await GDriveService().deleteFile(_base64Image!);
                  } catch (_) {}
                }
                setDialogState(() => _base64Image = '');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBrandDialog(StateSetter setParentState) {
    final controller = TextEditingController();
    _showAnimatedDialog(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Tambah Merk Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Masukkan nama merk (Contoh: Tesla)'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newBrand = controller.text.trim();
              if (newBrand.isNotEmpty) {
                if (!_brands.contains(newBrand)) {
                  setState(() {
                    _brands.add(newBrand);
                  });
                  await _syncBrandAndTypeListToAllCars();
                }
                setParentState(() => _selectedBrand = newBrand);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A469D)),
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManageBrandsDialog(StateSetter setParentState) {
    _showAnimatedDialog(
      child: StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Kelola Daftar Merk'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _brands.length,
              itemBuilder: (_, i) {
                final brand = _brands[i];
                final inUse = _cars.any((c) => c.brand == brand);
                return ListTile(
                  dense: true,
                  title: Text(brand),
                  trailing: inUse
                      ? const Tooltip(
                          message: 'Sedang dipakai oleh mobil',
                          child: Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Hapus merk',
                          onPressed: () async {
                            setState(() => _brands.removeAt(i));
                            setDialogState(() {});
                            setParentState(() {
                              if (_selectedBrand == brand) _selectedBrand = null;
                            });
                            await _syncBrandAndTypeListToAllCars();
                          },
                        ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        ),
      ),
    );
  }

  void _showAddTypeDialog(StateSetter setParentState) {
    final controller = TextEditingController();
    _showAnimatedDialog(
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Tambah Jenis Mobil Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Masukkan jenis (Contoh: Electric)'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newType = controller.text.trim();
              if (newType.isNotEmpty) {
                if (!_types.contains(newType)) {
                  setState(() {
                    _types.add(newType);
                  });
                  await _syncBrandAndTypeListToAllCars();
                }
                setParentState(() => _selectedType = newType);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A469D)),
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManageTypesDialog(StateSetter setParentState) {
    _showAnimatedDialog(
      child: StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Kelola Daftar Jenis'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _types.length,
              itemBuilder: (_, i) {
                final type = _types[i];
                final inUse = _cars.any((c) => c.type == type);
                return ListTile(
                  dense: true,
                  title: Text(type),
                  trailing: inUse
                      ? const Tooltip(
                          message: 'Sedang dipakai oleh mobil',
                          child: Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Hapus jenis',
                          onPressed: () async {
                            setState(() => _types.removeAt(i));
                            setDialogState(() {});
                            setParentState(() {
                              if (_selectedType == type) _selectedType = null;
                            });
                            await _syncBrandAndTypeListToAllCars();
                          },
                        ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        ),
      ),
    );
  }

  void _showCarDialog({Car? car}) {
    final isEdit = car != null;
    _editingCar = car;
    if (isEdit) {
      _nameController.text = car.name;
      _priceController.text = car.price.toString();
      _selectedBrand = car.brand;
      _selectedType = car.type;
      _stockController.text = car.stock.toString();
      _descriptionController.text = car.description;
      _base64Image = car.image;
      if (car.brand.isNotEmpty && !_brands.contains(car.brand)) {
        _brands.add(car.brand);
      }
      if (car.type.isNotEmpty && !_types.contains(car.type)) {
        _types.add(car.type);
      }
    } else {
      _clearCarForm();
    }

    _showAnimatedDialog(
      barrierDismissible: false,
      child: StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(isEdit ? 'Edit Mobil' : 'Tambah Mobil Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickImage(setDialogState),
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[100], border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                    child: _base64Image == null || _base64Image!.isEmpty
                        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Color(0xFF1A469D)), Text('Pilih Foto', style: TextStyle(fontSize: 12, color: Colors.grey))])
                        : ClipRRect(borderRadius: BorderRadius.circular(10), child: _displayImage(_base64Image!)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama Mobil')),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('brand_$_selectedBrand'),
                        initialValue: _brands.contains(_selectedBrand) ? _selectedBrand : null, 
                        decoration: const InputDecoration(labelText: 'Merk'),
                        items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedBrand = val),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1A469D)),
                      onPressed: () => _showAddBrandDialog(setDialogState),
                      tooltip: 'Tambah Merk Baru',
                    ),
                    IconButton(
                      icon: const Icon(Icons.manage_accounts, color: Colors.grey),
                      onPressed: () => _showManageBrandsDialog(setDialogState),
                      tooltip: 'Kelola Daftar Merk',
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('type_$_selectedType'),
                        initialValue: _types.contains(_selectedType) ? _selectedType : null,
                        decoration: const InputDecoration(labelText: 'Jenis'),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setDialogState(() => _selectedType = val),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1A469D)),
                      onPressed: () => _showAddTypeDialog(setDialogState),
                      tooltip: 'Tambah Jenis Baru',
                    ),
                    IconButton(
                      icon: const Icon(Icons.manage_accounts, color: Colors.grey),
                      onPressed: () => _showManageTypesDialog(setDialogState),
                      tooltip: 'Kelola Daftar Jenis',
                    ),
                  ],
                ),
                TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp '), keyboardType: TextInputType.number),
                TextField(controller: _stockController, decoration: const InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number),
                TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: _isSaving ? null : () async {
                if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedBrand == null || _selectedType == null) {
                  _showWarningDialog('Harap lengkapi semua data wajib!');
                  return;
                }
                Navigator.pop(context);
                await _saveOrUpdateCar();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A469D)),
              child: Text(isEdit ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDialog({User? user}) {
    final isEdit = user != null;
    _editingUser = user;
    if (isEdit) {
      _userNameController.text = user.name;
      _userEmailController.text = user.email;
      _userPhoneController.text = user.phone;
      _userPasswordController.text = user.password;
      _userBalanceController.text = user.balance.toString();
      _selectedRole = user.role.isNotEmpty ? user.role : 'user';
    } else {
      _clearUserForm();
    }

    _showAnimatedDialog(
      barrierDismissible: false,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          bool obscurePassword = true;
          return StatefulBuilder(
            builder: (context, setInnerState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _userNameController, decoration: const InputDecoration(labelText: 'Nama Lengkap *')),
                    TextField(controller: _userEmailController, decoration: const InputDecoration(labelText: 'Email *'), keyboardType: TextInputType.emailAddress),
                    TextField(controller: _userPhoneController, decoration: const InputDecoration(labelText: 'No. Telepon'), keyboardType: TextInputType.phone),
                    TextField(
                      controller: _userPasswordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setInnerState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    TextField(controller: _userBalanceController, decoration: const InputDecoration(labelText: 'Saldo Initial', prefixText: 'Rp '), keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Role *'),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _selectedRole = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: _isSaving ? null : () async {
                    if (_userNameController.text.isEmpty || _userEmailController.text.isEmpty || _userPasswordController.text.isEmpty) {
                      _showWarningDialog('Nama, Email, dan Password wajib diisi!');
                      return;
                    }
                    Navigator.pop(context);
                    await _saveOrUpdateUser();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A469D)),
                  child: Text(isEdit ? 'Update' : 'Simpan', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Future<void> _syncBrandAndTypeListToAllCars() async {
    final brandListStr = _brands.join(',');
    final typeListStr = _types.join(',');
    for (var car in _cars) {
      if (car.brandlist != brandListStr || car.typelist != typeListStr) {
        car.brandlist = brandListStr;
        car.typelist = typeListStr;
        try {
          await CarService().ubah(car, car.id);
        } catch (_) {}
      }
    }
  }

  Future<void> _saveOrUpdateCar() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final name = _nameController.text;
    final price = int.tryParse(_priceController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final desc = _descriptionController.text;
    final brandListStr = _brands.join(',');
    final typeListStr = _types.join(',');

    try {
      if (_editingCar == null) {
        final newCar = Car(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          price: price,
          brand: _selectedBrand ?? '',
          type: _selectedType ?? '',
          image: _base64Image ?? '',
          description: desc,
          stock: stock,
          brandlist: brandListStr,
          typelist: typeListStr,
        );
        await CarService().simpan(newCar);
      } else {
        _editingCar!.name = name;
        _editingCar!.brand = _selectedBrand ?? _editingCar!.brand;
        _editingCar!.type = _selectedType ?? _editingCar!.type;
        _editingCar!.price = price;
        _editingCar!.stock = stock;
        _editingCar!.description = desc;
        _editingCar!.image = _base64Image ?? _editingCar!.image;
        _editingCar!.brandlist = brandListStr;
        _editingCar!.typelist = typeListStr;
        await CarService().ubah(_editingCar!, _editingCar!.id);
      }
      _clearCarForm();
      await _loadAdminData();
      if (mounted) _showSuccessDialog('Data mobil berhasil disimpan.');
    } catch (e) {
      if (mounted) {
        if (e is NetworkException) {
          AppUtils.showNoNetworkDialog(context, onRetry: _saveOrUpdateCar);
        } else {
          _showWarningDialog('Gagal menyimpan mobil: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveOrUpdateUser() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final name = _userNameController.text;
    final email = _userEmailController.text;
    final phone = _userPhoneController.text;
    final password = _userPasswordController.text;
    final balance = int.tryParse(_userBalanceController.text) ?? 0;

    try {
      if (_editingUser == null) {
        final newUser = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          email: email,
          phone: phone,
          password: password,
          balance: balance,
          role: _selectedRole,
        );
        await UserService().simpan(newUser);
      } else {
        _editingUser!.name = name;
        _editingUser!.email = email;
        _editingUser!.phone = phone;
        _editingUser!.password = password;
        _editingUser!.balance = balance;
        _editingUser!.role = _selectedRole;
        await UserService().ubah(_editingUser!, _editingUser!.id);
      }
      _clearUserForm();
      await _loadAdminData();
      if (mounted) _showSuccessDialog('Data pengguna berhasil disimpan.');
    } catch (e) {
      if (mounted) {
        if (e is NetworkException) {
          AppUtils.showNoNetworkDialog(context, onRetry: _saveOrUpdateUser);
        } else {
          _showWarningDialog('Gagal menyimpan pengguna: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearCarForm() {
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedBrand = null;
      _selectedType = null;
      _base64Image = null;
      _editingCar = null;
    });
  }

  void _clearUserForm() {
    _userNameController.clear();
    _userEmailController.clear();
    _userPhoneController.clear();
    _userPasswordController.clear();
    _userBalanceController.clear();
    setState(() {
      _selectedRole = 'user';
      _editingUser = null;
    });
  }

  Widget _buildUserAvatar(String imagePath) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF1A469D),
      child: ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: buildNetworkImage(
            imagePath,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorWidget: const Icon(Icons.person, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _displayImage(String imageStr, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    return buildNetworkImage(
      imageStr,
      width: width,
      height: height,
      fit: fit,
      errorWidget: const Icon(Icons.broken_image),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
          backgroundColor: const Color(0xFFF7D117), 
          foregroundColor: Colors.black, 
          elevation: 0, 
          bottom: const TabBar(
            tabs: [Tab(icon: Icon(Icons.directions_car), text: 'Katalog'), Tab(icon: Icon(Icons.people), text: 'Pengguna')], 
            indicatorColor: Color(0xFF1A469D), 
            labelColor: Color(0xFF1A469D), 
            unselectedLabelColor: Colors.black54
          )
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
                      onPressed: () { setState(() => _error = null); _loadAdminData(); },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A469D), foregroundColor: Colors.white),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              children: [
                // Tab 1: Katalog Mobil (CRUD)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20), 
                      child: ElevatedButton.icon(
                        onPressed: () => _showCarDialog(), 
                        icon: const Icon(Icons.add, color: Colors.white), 
                        label: const Text('Tambah Mobil Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A469D), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
                      )
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
                        itemCount: _cars.length, 
                        separatorBuilder: (context, index) => const SizedBox(height: 10), 
                        itemBuilder: (context, index) {
                          final car = _cars[index];
                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), 
                            child: ListTile(
                              leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: _displayImage(car.image, width: 50, height: 50)), 
                              title: Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                              subtitle: Text('${car.brand} - ${AppUtils.formatRupiah(car.price)} (Stok: ${car.stock})'), 
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showCarDialog(car: car)), 
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red), 
                                    onPressed: () { 
                                      _showAnimatedDialog(
                                        child: AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
                                          title: const Text('Hapus Mobil'), 
                                          content: Text('Yakin ingin menghapus ${car.name}?'), 
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), 
                                            TextButton(
                                              onPressed: _isSaving ? null : () async { 
                                                Navigator.pop(context);
                                                if (mounted) setState(() => _isSaving = true);
                                                if (car.image.contains('googleusercontent.com') || car.image.contains('drive.google.com')) {
                                                  try { await GDriveService().deleteFile(car.image); } catch (_) {}
                                                }
                                                await CarService().hapus(car); 
                                                await _loadAdminData();
                                                if (mounted) setState(() => _isSaving = false);
                                              }, 
                                              child: const Text('Hapus', style: TextStyle(color: Colors.red))
                                            )
                                          ]
                                        )
                                      ); 
                                    }
                                  )
                                ]
                              )
                            )
                          );
                        }
                      )
                    ),
                  ]
                ),
                // Tab 2: Pengguna (CRUD)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton.icon(
                        onPressed: () => _showUserDialog(),
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text('Tambah Pengguna Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22bb33),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
                        itemCount: _users.length, 
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = _users[index]; 
                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), 
                            child: ListTile(
                              leading: _buildUserAvatar(user.profileImage), 
                              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                              subtitle: Text('${user.email} (${user.role.toUpperCase()})\nSaldo: ${AppUtils.formatRupiah(user.balance)}'), 
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () => _showUserDialog(user: user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showAnimatedDialog(
                                        child: AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          title: const Text('Hapus Pengguna'),
                                          content: Text('Yakin ingin menghapus pengguna ${user.name}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                            TextButton(
                                              onPressed: _isSaving ? null : () async {
                                                Navigator.pop(context);
                                                if (mounted) setState(() => _isSaving = true);
                                                if (user.profileImage.contains('googleusercontent.com') || user.profileImage.contains('drive.google.com')) {
                                                  try { await GDriveService().deleteFile(user.profileImage); } catch (_) {}
                                                }
                                                await UserService().hapus(user);
                                                await _loadAdminData();
                                                if (mounted) setState(() => _isSaving = false);
                                              },
                                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ]
            ),
      ),
    );
  }
}
