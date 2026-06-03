import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class IuranLocalCacheService {
  static const String _allBoxName = 'offline_cache_iuran_all';
  static const String _rwPrefix = 'offline_cache_iuran_rw_';

  String _rwBoxName(int rwId) => '$_rwPrefix$rwId';

  Future<void> cacheIuranList(List<Iuran> items) async {
    await _upsertCollection(
      boxName: _allBoxName,
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> cacheIuranRawList(List<Map<String, dynamic>> items) async {
    await _upsertCollection(boxName: _allBoxName, items: items);
  }

  Future<void> upsertIuranRaw(Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _allBoxName, items: [item]);
  }

  Future<void> cacheIuranRwList(int rwId, List<Iuran> items) async {
    await _upsertCollection(
      boxName: _rwBoxName(rwId),
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> upsertIuranRwRaw(int rwId, Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _rwBoxName(rwId), items: [item]);
  }

  Future<List<Map<String, dynamic>>> readIuranRaw() async {
    return _readCollection(_allBoxName);
  }

  Future<List<Map<String, dynamic>>> readIuranRwRaw(int rwId) async {
    return _readCollection(_rwBoxName(rwId));
  }

  Future<void> removeIuran(int id) async {
    final box = await HiveService().openBox<dynamic>(_allBoxName);
    await box.delete(id.toString());
  }

  Future<void> removeIuranRw(int rwId, int id) async {
    final box = await HiveService().openBox<dynamic>(_rwBoxName(rwId));
    await box.delete(id.toString());
  }

  Future<void> _upsertCollection({
    required String boxName,
    required Iterable<Map<String, dynamic>> items,
  }) async {
    final box = await HiveService().openBox<dynamic>(boxName);

    for (final item in items) {
      final id = (item['id'] as num?)?.toInt();
      if (id == null) {
        continue;
      }

      await box.put(id.toString(), Map<String, dynamic>.from(item));
    }
  }

  Future<List<Map<String, dynamic>>> _readCollection(String boxName) async {
    final box = await HiveService().openBox<dynamic>(boxName);
    final items = <Map<String, dynamic>>[];

    for (final value in box.values) {
      if (value is Map) {
        final mapped = Map<String, dynamic>.from(value);
        if (mapped['is_deleted'] == true) {
          continue;
        }

        items.add(mapped);
      }
    }

    items.sort((a, b) {
      final aTime =
          DateTime.tryParse(a['waktu_dibuat'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          DateTime.tryParse(b['waktu_dibuat'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final timeCompare = bTime.compareTo(aTime);
      if (timeCompare != 0) {
        return timeCompare;
      }

      final left = (a['id'] as num?)?.toInt() ?? 0;
      final right = (b['id'] as num?)?.toInt() ?? 0;
      return right.compareTo(left);
    });

    return items;
  }
}
