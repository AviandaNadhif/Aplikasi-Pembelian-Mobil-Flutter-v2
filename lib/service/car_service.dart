import 'package:dio/dio.dart';
import '../helpers/api_client.dart';
import '../model/car.dart';

/// Layanan service untuk pengelolaan data mobil (CRUD) via REST API.
class CarService {
  /// Mengambil seluruh daftar data mobil dari server API.
  Future<List<Car>> listData() async {
    final Response response = await ApiClient().get('cars');
    final List data = response.data as List;
    List<Car> result = data.map((json) => Car.fromJson(Map<String, dynamic>.from(json))).toList();
    return result;
  }

  /// Menyimpan unit mobil baru ke server API.
  Future<Car> simpan(Car car) async {
    car.id = DateTime.now().millisecondsSinceEpoch.toString();
    var data = car.toJson();
    final Response response = await ApiClient().post('cars', data);
    Car result = Car.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Memperbarui data mobil yang ada di server API berdasarkan [id].
  Future<Car> ubah(Car car, String id) async {
    var data = car.toJson();
    final Response response = await ApiClient().put('cars/$id', data);
    Car result = Car.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Mengambil detail satu unit mobil berdasarkan [id].
  Future<Car> getById(String id) async {
    final Response response = await ApiClient().get('cars/$id');
    Car result = Car.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }

  /// Menghapus data unit [car] dari server API.
  Future<Car> hapus(Car car) async {
    final Response response = await ApiClient().delete('cars/${car.id}');
    Car result = Car.fromJson(Map<String, dynamic>.from(response.data));
    return result;
  }
}

