import 'package:dio/dio.dart';
import '../api/dio_client.dart';

class CloudSetoranIuranRtService {
  final Dio _dio = DioClient().dio;

  // GET ALL
  Future<Map<String, dynamic>> getAllSetoran(String token) async {
    final response = await _dio.get(
      '/setoran',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // GET BY ID
  Future<Map<String, dynamic>> getSetoranById(
    int id,
    String token,
  ) async {
    final response = await _dio.get(
      '/setoran/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // GET BY RT
  Future<Map<String, dynamic>> getSetoranByRT(
    int rtId,
    String token,
  ) async {
    final response = await _dio.get(
      '/setoran/rt/$rtId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // GET BY IURAN + RT
  Future<Map<String, dynamic>> getSetoranByIuranRT(
    int iuranId,
    int rtId,
    String token,
  ) async {
    final response = await _dio.get(
      '/setoran/iuran/$iuranId/rt/$rtId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // GET BY PERIODE
  Future<Map<String, dynamic>> getSetoranByPeriode(
    int iuranId,
    int rtId,
    String periode,
    String token,
  ) async {
    final response = await _dio.get(
      '/setoran/iuran/$iuranId/rt/$rtId/periode/$periode',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // CREATE
  Future<Map<String, dynamic>> createSetoran(
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.post(
      '/setoran',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // APPROVE
  Future<Map<String, dynamic>> approveSetoran(
    int id,
    String token,
  ) async {
    final response = await _dio.put(
      '/setoran/$id/approve',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // REJECT
  Future<Map<String, dynamic>> rejectSetoran(
    int id,
    String catatan,
    String token,
  ) async {
    final response = await _dio.put(
      '/setoran/$id/reject',
      data: {'catatan': catatan},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // UPDATE
  Future<Map<String, dynamic>> updateSetoran(
    int id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await _dio.put(
      '/setoran/$id',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  // DELETE
  Future<Map<String, dynamic>> deleteSetoran(
    int id,
    String token,
  ) async {
    final response = await _dio.delete(
      '/setoran/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }
}