import 'package:dio/dio.dart';
import '../helpers/api_client.dart';
import '../model/transaction.dart';

/// Layanan service untuk pengelolaan data transaksi/struk riwayat pembelian via REST API.
class TransactionService {
  /// Mengambil daftar seluruh riwayat transaksi dari server API.
  Future<List<Transaction>> listData() async {
    final Response response = await ApiClient().get('transactions');
    final List data = response.data as List;
    List<Transaction> result = data.map((json) => Transaction.fromJson(Map<String, dynamic>.from(json))).toList();
    return result;
  }

  /// Menyimpan data transaksi [transaction] baru ke server API.
  Future<Transaction> simpan(Transaction transaction) async {
    transaction.id = DateTime.now().millisecondsSinceEpoch.toString();
    var data = transaction.toJson();
    final Response response = await ApiClient().post('transactions', data);
    Transaction result = Transaction.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Memperbarui data transaksi [transaction] berdasarkan [id].
  Future<Transaction> ubah(Transaction transaction, String id) async {
    var data = transaction.toJson();
    final Response response = await ApiClient().put('transactions/$id', data);
    Transaction result = Transaction.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Mengambil detail satu transaksi berdasarkan [id].
  Future<Transaction> getById(String id) async {
    final Response response = await ApiClient().get('transactions/$id');
    Transaction result = Transaction.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Menghapus data transaksi [transaction] dari server API.
  Future<Transaction> hapus(Transaction transaction) async {
    final Response response = await ApiClient().delete('transactions/${transaction.id}');
    Transaction result = Transaction.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }
}

