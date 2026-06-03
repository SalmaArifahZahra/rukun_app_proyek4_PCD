import 'package:dio/dio.dart';
import 'package:rukun_app_proyek4/models/dashboard_model.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_dashboard_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/local/local_dashboard_cache_service.dart';

class DashboardRepository {
  final CloudDashboardService service;
  final AuthLocalService local;
  final DashboardLocalCacheService _cache = DashboardLocalCacheService();

  DashboardRepository(this.service, this.local);

  Future<DashboardModel> getDashboardRW() async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(() => service.getDashboardRW(token));
      _validateStatus(result);

      final data = result['data'] as Map<String, dynamic>;
      await _cache.saveRaw('rw', data);

      return DashboardModel.fromJson(data);
    } catch (e) {
      if (_canUseCache(e)) {
        final cached = await _cache.readRaw('rw');
        if (cached != null) return DashboardModel.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<DashboardModel> getDashboardRT() async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(() => service.getDashboardRT(token));
      _validateStatus(result);

      final data = result['data'] as Map<String, dynamic>;
      await _cache.saveRaw('rt', data);

      return DashboardModel.fromJson(data);
    } catch (e) {
      if (_canUseCache(e)) {
        final cached = await _cache.readRaw('rt');
        if (cached != null) return DashboardModel.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<String> _requireToken() async {
    final token = await local.getToken();

    if (token == null) {
      throw Exception("Token tidak ditemukan. Silakan login ulang.");
    }

    return token;
  }

  Future<Map<String, dynamic>> _safeCall(
    Future<Map<String, dynamic>> Function() fn,
  ) async {
    try {
      return await fn();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  void _validateStatus(Map<String, dynamic> result) {
    if (result['status'] != 'success') {
      throw Exception(result['message'] ?? "Unknown error");
    }
  }

  bool _canUseCache(Object error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.unknown => true,
        _ => false,
      };
    }

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable');
  }
}
