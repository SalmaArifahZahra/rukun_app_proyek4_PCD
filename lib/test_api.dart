import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://rukun_app_be.ridhosulistyo1302.workers.dev/api/v1',
  ));

  dio.httpClientAdapter = IOHttpClientAdapter()
    ..createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

  try {
    print('Testing login...');
    try {
      await dio.post('/auth/login', data: {'nik': '1', 'password': '1'});
    } on DioException catch (e) {
      print('Login Status: ${e.response?.statusCode}');
      print('Login Data: ${e.response?.data}');
    }

    print('\nTesting /keluarga...');
    try {
      await dio.post('/keluarga', data: {
        'no_kk': '1231231231231231',
        'rt_id': 1
      });
    } on DioException catch (e) {
      print('Keluarga Status: ${e.response?.statusCode}');
      print('Keluarga Data: ${e.response?.data}');
    }

  } catch (e) {
    print(e);
  }
}
