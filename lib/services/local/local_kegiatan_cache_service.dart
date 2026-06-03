import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class KegiatanLocalCacheService {
  final HiveService _hive = HiveService();
  final String _boxName = 'offline_cache_kegiatan';

  Future<void> cacheKegiatanRawList(List<Map<String, dynamic>> items) async {
    final box = await _hive.openBox(_boxName);
    for (final item in items) {
      final id = (item['id'] as num?)?.toInt();
      if (id == null) continue;
      await box.put(id.toString(), Map<String, dynamic>.from(item));
    }
  }

  Future<void> upsertKegiatanRaw(Map<String, dynamic> item) async {
    final box = await _hive.openBox(_boxName);
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    await box.put(id.toString(), Map<String, dynamic>.from(item));
  }

  Future<List<Map<String, dynamic>>> readKegiatanRaw() async {
    final box = await _hive.openBox(_boxName);
    final items = <Map<String, dynamic>>[];
    for (final value in box.values) {
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        if (map['waktu_dihapus'] == null) {
          items.add(map);
        }
      }
    }
    items.sort((a, b) {
      final aTime = a['waktu_dibuat'] as String? ?? '';
      final bTime = b['waktu_dibuat'] as String? ?? '';
      return bTime.compareTo(aTime);
    });
    return items;
  }

  Future<void> removeKegiatan(int id) async {
    final box = await _hive.openBox(_boxName);
    await box.delete(id.toString());
  }
}
