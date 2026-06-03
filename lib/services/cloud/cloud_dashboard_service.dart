import 'package:dio/dio.dart';
import '../api/dio_client.dart';

class CloudDashboardService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getDashboardRW(String token) async {
    final response = await _dio.get(
      '/dashboard/rw',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getDashboardRT(String token) async {
    final response = await _dio.get(
      '/dashboard/rt',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data;
  }
}
