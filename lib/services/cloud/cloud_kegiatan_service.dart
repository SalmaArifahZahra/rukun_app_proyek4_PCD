import 'package:dio/dio.dart';
import '../api/dio_client.dart';

class CloudKegiatanService {
  final Dio _dio = DioClient().dio;

  Options _authHeader(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> getAllKegiatan(String token) async {
    final response = await _dio.get('/kegiatan', options: _authHeader(token));

    return response.data;
  }

  Future<Map<String, dynamic>> getKegiatanById(int id, String token) async {
    final response = await _dio.get(
      '/kegiatan/$id',
      options: _authHeader(token),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getKegiatanByRW(int rwId, String token) async {
    final response = await _dio.get(
      '/kegiatan/rw/$rwId',
      options: _authHeader(token),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> createKegiatan(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.post(
      '/kegiatan',
      data: data,
      options: _authHeader(token),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> updateKegiatan(
    int id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.put(
      '/kegiatan/$id',
      data: data,
      options: _authHeader(token),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> deleteKegiatan(int id, String token) async {
    final response = await _dio.delete(
      '/kegiatan/$id',
      options: _authHeader(token),
    );

    return response.data;
  }
}
