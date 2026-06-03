import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class SuratLocalCacheService {
  static const String _allBoxName = 'offline_cache_surat_all';
  static const String _sayaBoxName = 'offline_cache_surat_saya';

  String _rtBoxName(int rtId) => 'offline_cache_surat_rt_$rtId';
  String _rwBoxName(int rwId) => 'offline_cache_surat_rw_$rwId';

  Future<void> cacheSuratAllList(List<PengajuanSurat> items) async {
    await _upsertCollection(
      boxName: _allBoxName,
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> cacheSuratSayaList(List<PengajuanSurat> items) async {
    await _upsertCollection(
      boxName: _sayaBoxName,
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> cacheSuratRtList(int rtId, List<PengajuanSurat> items) async {
    await _upsertCollection(
      boxName: _rtBoxName(rtId),
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> cacheSuratRwList(int rwId, List<PengajuanSurat> items) async {
    await _upsertCollection(
      boxName: _rwBoxName(rwId),
      items: items.map((item) => item.toJson()),
    );
  }

  Future<void> upsertSuratAllRaw(Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _allBoxName, items: [item]);
  }

  Future<void> upsertSuratSayaRaw(Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _sayaBoxName, items: [item]);
  }

  Future<void> upsertSuratRtRaw(int rtId, Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _rtBoxName(rtId), items: [item]);
  }

  Future<void> upsertSuratRwRaw(int rwId, Map<String, dynamic> item) async {
    await _upsertCollection(boxName: _rwBoxName(rwId), items: [item]);
  }

  Future<List<Map<String, dynamic>>> readSuratAllRaw() async {
    return _readCollection(_allBoxName);
  }

  Future<List<Map<String, dynamic>>> readSuratSayaRaw() async {
    return _readCollection(_sayaBoxName);
  }

  Future<List<Map<String, dynamic>>> readSuratRtRaw(int rtId) async {
    return _readCollection(_rtBoxName(rtId));
  }

  Future<List<Map<String, dynamic>>> readSuratRwRaw(int rwId) async {
    return _readCollection(_rwBoxName(rwId));
  }

  Future<void> removeSuratAll(int id) async {
    final box = await HiveService().openBox<dynamic>(_allBoxName);
    await box.delete(id.toString());
  }

  Future<void> removeSuratSaya(int id) async {
    final box = await HiveService().openBox<dynamic>(_sayaBoxName);
    await box.delete(id.toString());
  }

  Future<void> removeSuratRt(int rtId, int id) async {
    final box = await HiveService().openBox<dynamic>(_rtBoxName(rtId));
    await box.delete(id.toString());
  }

  Future<void> removeSuratRw(int rwId, int id) async {
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
