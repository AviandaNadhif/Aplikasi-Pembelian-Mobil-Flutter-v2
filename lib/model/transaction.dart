import 'car.dart';

/// Model data yang merepresentasikan riwayat transaksi / pembelian mobil.
class Transaction {
  String id;
  String userId;
  String resi;
  String buyerName;
  String buyerEmail;
  int totalItem;
  int totalPrice;
  String date; // Disimpan sebagai String sesuai MockAPI
  String itemsDetails;

  /// Membuat instance [Transaction] baru.
  Transaction({
    this.id = '',
    this.userId = '',
    required this.resi,
    required this.buyerName,
    required this.buyerEmail,
    required this.totalItem,
    required this.totalPrice,
    required this.date,
    this.itemsDetails = '',
  });

  /// Mengonversi objek [Transaction] menjadi Map JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'resi': resi,
        'buyerName': buyerName,
        'buyerEmail': buyerEmail,
        'totalItem': totalItem,
        'totalPrice': totalPrice,
        'date': date,
        'itemsDetails': itemsDetails,
      };

  /// Mengkonstruksi objek [Transaction] dari Map JSON.
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        resi: json['resi']?.toString() ?? '',
        buyerName: json['buyerName']?.toString() ?? '',
        buyerEmail: json['buyerEmail']?.toString() ?? '',
        totalItem: parseInt(json['totalItem']),
        totalPrice: parseInt(json['totalPrice']),
        date: json['date']?.toString() ?? '',
        itemsDetails: json['itemsDetails']?.toString() ?? '',
      );
}

