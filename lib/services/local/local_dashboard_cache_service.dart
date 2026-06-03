import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class DashboardLocalCacheService {
  final HiveService _hive = HiveService();
  final String _boxName = 'cache_dashboard';

  Future<void> saveRaw(String key, Map<String, dynamic> data) async {
    final box = await _hive.openBox(_boxName);
    await box.put(key, data);
  }

  Future<Map<String, dynamic>?> readRaw(String key) async {
    final box = await _hive.openBox(_boxName);
    final raw = box.get(key);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }
}
