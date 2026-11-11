import 'package:dio/dio.dart';
import '../helpers/api_client.dart';
import '../model/cart_item.dart';

/// Layanan service untuk pengelolaan keranjang belanja (Cart) pengguna via REST API.
class CartService {
  /// Mengambil daftar seluruh item keranjang belanja dari server API.
  Future<List<CartItem>> listData() async {
    final Response response = await ApiClient().get('carts');
    final List data = response.data as List;
    List<CartItem> result = data.map((json) => CartItem.fromJson(Map<String, dynamic>.from(json))).toList();
    return result;
  }

  /// Menyimpan atau meng-update item [cartItem] ke keranjang belanja dengan validasi stok [maxStock].
  Future<CartItem> simpan(CartItem cartItem, {int? maxStock}) async {
    try {
      final existingItems = await listData();
      CartItem? match;
      for (var item in existingItems) {
        if (item.userId == cartItem.userId) {
          if ((cartItem.carId.isNotEmpty && item.carId == cartItem.carId) ||
              (cartItem.name.isNotEmpty && item.name.toLowerCase() == cartItem.name.toLowerCase())) {
            match = item;
            break;
          }
        }
      }

      int currentQty = match?.qty ?? 0;
      if (maxStock != null && (currentQty + cartItem.qty) > maxStock) {
        throw Exception("Kuantitas di keranjang melebihi stok yang tersedia (Stok: $maxStock)");
      }

      if (match != null && match.id.isNotEmpty) {
        final newQty = match.qty + cartItem.qty;
        final newTotalPrice = match.price * newQty;
        final updatedItem = CartItem(
          id: match.id,
          userId: match.userId,
          carId: match.carId.isNotEmpty ? match.carId : cartItem.carId,
          name: match.name,
          brand: match.brand,
          price: match.price,
          qty: newQty,
          totalPrice: newTotalPrice,
          image: match.image,
        );
        return await ubah(updatedItem, match.id);
      }
    } catch (e) {
      if (e.toString().contains("melebihi stok")) {
        rethrow;
      }
    }

    if (maxStock != null && cartItem.qty > maxStock) {
      throw Exception("Kuantitas di keranjang melebihi stok yang tersedia (Stok: $maxStock)");
    }

    cartItem.id = DateTime.now().millisecondsSinceEpoch.toString();
    var data = cartItem.toJson();
    final Response response = await ApiClient().post('carts', data);
    CartItem result = CartItem.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Memperbarui data item keranjang [cartItem] berdasarkan [id].
  Future<CartItem> ubah(CartItem cartItem, String id) async {
    var data = cartItem.toJson();
    final Response response = await ApiClient().put('carts/$id', data);
    CartItem result = CartItem.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Mengambil data item keranjang berdasarkan [id].
  Future<CartItem> getById(String id) async {
    final Response response = await ApiClient().get('carts/$id');
    CartItem result = CartItem.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Menghapus [cartItem] dari keranjang belanja.
  Future<CartItem> hapus(CartItem cartItem) async {
    final Response response = await ApiClient().delete('carts/${cartItem.id}');
    CartItem result = CartItem.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Mengosongkan keranjang belanja untuk [userId] tertentu atau seluruh keranjang jika [userId] null.
  Future<void> clearCart([String? userId]) async {
    try {
      final items = await listData();
      for (var item in items) {
        if (item.id.isNotEmpty) {
          if (userId == null || userId.isEmpty || item.userId == userId) {
            await hapus(item);
          }
        }
      }
    } catch (_) {}
  }
}

