import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class SetoranIuranLocalCacheService {
  final HiveService _hive = HiveService();
  final String boxName = 'cache_setoran_iuran_rt';

  Future<void> cacheSetoranRawList(List<Map<String, dynamic>> items) async {
    final box = await _hive.openBox(boxName);
    await box.put('all', items);
  }

  Future<List<Map<String, dynamic>>> readSetoranRaw() async {
    final box = await _hive.openBox(boxName);
    final raw = box.get('all');
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<void> upsertSetoranRaw(Map<String, dynamic> item) async {
    final list = await readSetoranRaw();
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    final idx = list.indexWhere((e) => (e['id'] as num?)?.toInt() == id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.add(item);
    }
    await cacheSetoranRawList(list);
  }

  Future<void> removeSetoran(int id) async {
    final list = await readSetoranRaw();
    list.removeWhere((e) => (e['id'] as num?)?.toInt() == id);
    await cacheSetoranRawList(list);
  }
}
