import 'car.dart';

/// Model data yang merepresentasikan informasi akun pengguna dan saldo.
class User {
  String id;
  String name;
  String email;
  String phone;
  String password;
  int balance;
  int spent;
  String profileImage;
  String role;
  String googlelogin; // 'google' jika login via Google, '' jika login biasa

  /// Membuat instance [User] baru.
  User({
    this.id = '',
    required this.name,
    required this.email,
    this.phone = '',
    required this.password,
    this.balance = 0,
    this.spent = 0,
    this.profileImage = '',
    String? role,
    this.googlelogin = '',
  }) : role = (email.trim().toLowerCase() == 'aviandanadhif25@gmail.com') ? 'admin' : (role ?? 'user');

  /// Mengembalikan `true` jika akun ini terdaftar/login melalui Google OAuth.
  bool get isGoogleUser => googlelogin == 'google';

  /// Mengonversi objek [User] menjadi Map JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'balance': balance,
        'spent': spent,
        'profileImage': profileImage,
        'role': role,
        'googlelogin': googlelogin,
      };

  /// Mengkonstruksi objek [User] dari Map JSON.
  factory User.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString() ?? '';
    final role = email.trim().toLowerCase() == 'aviandanadhif25@gmail.com'
        ? 'admin'
        : (json['role']?.toString() ?? 'user');
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: email,
      phone: json['phone']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      balance: parseInt(json['balance']),
      spent: parseInt(json['spent']),
      profileImage: json['profileImage']?.toString() ?? '',
      role: role,
      googlelogin: json['googlelogin']?.toString() ?? '',
    );
  }
}

