/// Mengonversi nilai [value] dari berbagai tipe data (int, double, String) ke [int].
int parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Model data yang merepresentasikan informasi unit mobil.
class Car {
  String id;
  String name;
  int price;
  String brand;
  String type;
  String image;
  String description;
  int stock;
  String typelist;
  String brandlist;

  /// Membuat instance [Car] baru.
  Car({
    this.id = '',
    required this.name,
    required this.price,
    required this.brand,
    required this.type,
    required this.image,
    required this.description,
    required this.stock,
    this.typelist = '',
    this.brandlist = '',
  });

  /// Mengonversi objek [Car] menjadi Map JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'brand': brand,
        'type': type,
        'image': image,
        'description': description,
        'stock': stock,
        'typelist': typelist,
        'brandlist': brandlist,
      };

  /// Mengkonstruksi objek [Car] dari Map JSON.
  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        price: parseInt(json['price']),
        brand: json['brand']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        stock: parseInt(json['stock']),
        typelist: json['typelist']?.toString() ?? '',
        brandlist: json['brandlist']?.toString() ?? '',
      );
}

