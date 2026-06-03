import 'package:dio/dio.dart';
import '../api/dio_client.dart';

class CloudKasMutasiService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getAllKasMutasi(String token) async {
    final response = await _dio.get(
      '/kas-mutasi',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getKasMutasiById(
    int id,
    String token,
  ) async {
    final response = await _dio.get(
      '/kas-mutasi/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getKasMutasiByRT(
    int rtId,
    String token,
  ) async {
    final response = await _dio.get(
      '/kas-mutasi/rt/$rtId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getKasMutasiByRW(
    int rwId,
    String token,
  ) async {
    final response = await _dio.get(
      '/kas-mutasi/rw/$rwId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> createKasMutasi(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.post(
      '/kas-mutasi',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> updateKasMutasi(
    int id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.put(
      '/kas-mutasi/$id',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> deleteKasMutasi(
    int id,
    String token,
  ) async {
    final response = await _dio.delete(
      '/kas-mutasi/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }
}