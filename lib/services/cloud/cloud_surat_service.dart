import 'package:dio/dio.dart';
import '../api/dio_client.dart';

class CloudSuratService {
  final Dio _dio = DioClient().dio;

  Options _authHeader(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // GET ALL
  Future<Map<String, dynamic>> getAllSurat(String token) async {
    final response = await _dio.get(
      '/pengajuan-surat',
      options: _authHeader(token),
    );

    return response.data;
  }

  // GET SURAT SAYA
  Future<Map<String, dynamic>> getSuratSaya(String token) async {
    final response = await _dio.get(
      '/pengajuan-surat/me',
      options: _authHeader(token),
    );

    return response.data;
  }

  // GET BY ID
  Future<Map<String, dynamic>> getSuratById(int id, String token) async {
    final response = await _dio.get(
      '/pengajuan-surat/$id',
      options: _authHeader(token),
    );

    return response.data;
  }

  // GET BY RT
  Future<Map<String, dynamic>> getSuratByRt(int rtId, String token) async {
    final response = await _dio.get(
      '/pengajuan-surat/rt/$rtId',
      options: _authHeader(token),
    );

    return response.data;
  }

  // GET BY RW
  Future<Map<String, dynamic>> getSuratByRw(int rwId, String token) async {
    final response = await _dio.get(
      '/pengajuan-surat/rw/$rwId',
      options: _authHeader(token),
    );

    return response.data;
  }

  // CREATE
  Future<Map<String, dynamic>> createSurat(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.post(
      '/pengajuan-surat',
      data: data,
      options: _authHeader(token),
    );

    return response.data;
  }

  // UPDATE STATUS
  Future<Map<String, dynamic>> updateSurat(
    int id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.put(
      '/pengajuan-surat/$id',
      data: data,
      options: _authHeader(token),
    );

    return response.data;
  }

  // DELETE
  Future<Map<String, dynamic>> deleteSurat(int id, String token) async {
    final response = await _dio.delete(
      '/pengajuan-surat/$id',
      options: _authHeader(token),
    );

    return response.data;
  }
}
