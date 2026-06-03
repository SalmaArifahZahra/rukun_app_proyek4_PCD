import 'package:hive/hive.dart';
import '../utils/hive_service.dart';

class AuthLocalService {
  final HiveService _hiveService;

  AuthLocalService(this._hiveService);

  Future<Box> _box() async {
    return await _hiveService.openBox('auth');
  }

  Future<void> saveToken(String token) async {
    final box = await _box();
    await box.put('token', token);
  }

  Future<String?> getToken() async {
    final box = await _box();
    return box.get('token');
  }

  Future<void> clearToken() async {
    final box = await _box();
    await box.delete('token');
  }

  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    final box = await _box();
    await box.put('user', userJson);
  }

  Future<Map<String, dynamic>?> getUserJson() async {
    final box = await _box();
    final raw = box.get('user');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }
}
