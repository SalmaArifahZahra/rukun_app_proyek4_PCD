import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class PendudukLocalCacheService {
  static const String _keluargaBoxName = 'offline_cache_keluarga';
  static const String _wargaBoxName = 'offline_cache_warga';

  Future<void> cacheKeluargaList(List<Keluarga> items) async {
    await _upsertCollection(
      boxName: _keluargaBoxName,
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> cacheKeluargaRawList(List<Map<String, dynamic>> items) async {
    await _upsertCollection(boxName: _keluargaBoxName, items: items);
  }

  Future<void> upsertKeluargaRaw(Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _keluargaBoxName, items: [item]);
  }

  Future<void> cacheWargaList(List<Warga> items) async {
    await _upsertCollection(
      boxName: _wargaBoxName,
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> cacheWargaRawList(List<Map<String, dynamic>> items) async {
    await _upsertCollection(boxName: _wargaBoxName, items: items);
  }

  Future<void> upsertWargaRaw(Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _wargaBoxName, items: [item]);
  }

  Future<List<Map<String, dynamic>>> readKeluargaRaw() async {
    return _readCollection(_keluargaBoxName);
  }

  Future<List<Map<String, dynamic>>> readWargaRaw() async {
    return _readCollection(_wargaBoxName);
  }

  Future<void> removeKeluarga(int id) async {
    final box = await HiveService().openBox<dynamic>(_keluargaBoxName);
    await box.delete(id.toString());
  }

  Future<void> removeWarga(int id) async {
    final box = await HiveService().openBox<dynamic>(_wargaBoxName);
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
      final left = (a['id'] as num?)?.toInt() ?? 0;
      final right = (b['id'] as num?)?.toInt() ?? 0;
      return right.compareTo(left);
    });

    return items;
  }
}
