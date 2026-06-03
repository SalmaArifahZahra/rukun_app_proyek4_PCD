import 'package:dio/dio.dart';
import 'package:rukun_app_proyek4/models/auth_response_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_auth_service.dart';

class AuthRepository {
  final CloudAuthService service;
  final AuthLocalService local;

  AuthRepository(this.service, this.local);

  Future<AuthResponse> login(String nik, String password) async {
    final result = await _safeCall(() => service.login(nik, password));

    _validateStatus(result);

    final data = result['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception("Format login response tidak valid");
    }

    final token = data['token'];

    await local.saveToken(token);

    final me = await service.getMe(token);

    _validateStatus(me);

    final userData = me['data'];

    if (userData is! Map<String, dynamic>) {
      throw Exception("Format user tidak valid");
    }

    final user = User.fromJson(userData);

    await local.saveUserJson(userData);

    return AuthResponse(token: token, user: user);
  }

  Future<void> register({
    required String nik,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await _safeCall(
      () => service.register(
        nik: nik,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );

    _validateStatus(result);
  }

  Future<void> logout() async {
    await local.clear();
  }

  Future<String?> getToken() async {
    return await local.getToken();
  }

  Future<User> getMe(String token) async {
    final result = await _safeCall(() => service.getMe(token));

    _validateStatus(result);

    final userData = result['data'] as Map<String, dynamic>;
    await local.saveUserJson(userData);

    return User.fromJson(userData);
  }

  Future<User?> getCachedUser() async {
    final json = await local.getUserJson();
    if (json == null) return null;
    return User.fromJson(json);
  }

  Future<User?> getUserByWargaId(int wargaId) async {
    final token = await local.getToken();

    if (token == null) {
      throw Exception("Token tidak ditemukan. Silakan login ulang.");
    }

    final result = await _safeCall(
      () => service.getUserByWargaId(wargaId, token),
    );

    _validateStatus(result);

    final data = result['data'];

    if (data == null) return null;

    return User.fromJson(data);
  }

  Future<void> adminChangePassword(int userId, String password) async {
    final token = await local.getToken();

    if (token == null) {
      throw Exception("Token tidak ditemukan. Silakan login ulang.");
    }

    final result = await _safeCall(
      () => service.adminChangePassword(userId, password, token),
    );

    _validateStatus(result);
  }

  Future<Map<String, dynamic>> _safeCall(Future<dynamic> Function() fn) async {
    try {
      final res = await fn();

      if (res is Map<String, dynamic>) {
        return res;
      }

      throw Exception("Response bukan Map: ${res.runtimeType}");
    } on DioException {
      rethrow;
    }
  }

  void _validateStatus(Map<String, dynamic> result) {
    final status = result['status'];

    if (status != 'success') {
      throw Exception(result['message'] ?? "Unknown error");
    }
  }
}
