import 'car.dart';

/// Model data yang merepresentasikan item dalam keranjang belanja user.
class CartItem {
  String id;
  String userId;
  String carId;
  String name;
  String brand;
  int price;
  int qty;
  int totalPrice;
  String image;

  /// Membuat instance [CartItem] baru.
  CartItem({
    this.id = '',
    required this.userId,
    required this.carId,
    required this.name,
    required this.brand,
    required this.price,
    this.qty = 1,
    required this.totalPrice,
    required this.image,
  });

  /// Mengonversi objek [CartItem] menjadi Map JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'carId': carId,
        'name': name,
        'brand': brand,
        'price': price,
        'qty': qty,
        'totalPrice': totalPrice,
        'image': image,
      };

  /// Mengkonstruksi objek [CartItem] dari Map JSON.
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        carId: json['carId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        brand: json['brand']?.toString() ?? '',
        price: parseInt(json['price']),
        qty: parseInt(json['qty']) <= 0 ? 1 : parseInt(json['qty']),
        totalPrice: parseInt(json['totalPrice']),
        image: json['image']?.toString() ?? '',
      );
}

