import 'package:dio/dio.dart';
import 'package:rukun_app_proyek4/models/kas_mutasi_model.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_mutasi_service.dart';

class KasMutasiRepository {
  final CloudKasMutasiService service;
  final AuthLocalService local;

  KasMutasiRepository(this.service, this.local);

  Future<List<KasMutasi>> getAllKasMutasi() async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.getAllKasMutasi(token),
    );

    _validateStatus(result);

    final List data = result['data'] ?? [];

    return data.map((e) => KasMutasi.fromJson(e)).toList();
  }

  Future<KasMutasi?> getKasMutasiById(int id) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.getKasMutasiById(id, token),
    );

    _validateStatus(result);

    final data = result['data'];

    if (data == null) return null;

    return KasMutasi.fromJson(data);
  }

  Future<List<KasMutasi>> getKasMutasiByRT(int rtId) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.getKasMutasiByRT(rtId, token),
    );

    _validateStatus(result);

    final List data = result['data'] ?? [];

    return data.map((e) => KasMutasi.fromJson(e)).toList();
  }

  Future<List<KasMutasi>> getKasMutasiByRW(int rwId) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.getKasMutasiByRW(rwId, token),
    );

    _validateStatus(result);

    final List data = result['data'] ?? [];

    return data.map((e) => KasMutasi.fromJson(e)).toList();
  }

  Future<void> createKasMutasi(KasMutasi data) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.createKasMutasi(data.toJson(), token),
    );

    _validateStatus(result);
  }

  Future<void> updateKasMutasi(int id, KasMutasi data) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.updateKasMutasi(id, data.toJson(), token),
    );

    _validateStatus(result);
  }

  Future<void> deleteKasMutasi(int id) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.deleteKasMutasi(id, token),
    );

    _validateStatus(result);
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
}