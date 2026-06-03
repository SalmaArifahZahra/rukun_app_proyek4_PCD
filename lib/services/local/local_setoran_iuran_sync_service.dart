import 'package:uuid/uuid.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';
import 'package:rukun_app_proyek4/services/local/offline_sync_status_service.dart';

class SetoranIuranLocalSyncService {
  final HiveService _hive = HiveService();
  final String boxName = 'offline_sync_setoran';

  Future<String> queueCreateSetoran({
    required int tempId,
    required Map<String, dynamic> payload,
  }) async {
    final box = await _hive.openBox(boxName);
    final id = const Uuid().v4();
    final entry = {
      'queue_id': id,
      'entity': 'setoran',
      'operation': 'create',
      'entity_id': tempId,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    };
    final list = (box.get('pending') as List?) ?? [];
    list.add(entry);
    await box.put('pending', list);
    await OfflineSyncStatusService.instance.refresh();
    return id;
  }

  Future<String> queueUpdateSetoran({
    required int entityId,
    required Map<String, dynamic> payload,
  }) async {
    final box = await _hive.openBox(boxName);
    // if there's existing create action for this temp id, merge
    final list = (box.get('pending') as List?) ?? [];
    final existing = list.firstWhere(
      (e) =>
          e['entity'] == 'setoran' &&
          e['entity_id'] == entityId &&
          e['operation'] == 'create',
      orElse: () => null,
    );
    if (existing != null) {
      existing['payload'] = {...existing['payload'], ...payload};
      await box.put('pending', list);
      await OfflineSyncStatusService.instance.refresh();
      return existing['queue_id'];
    }

    final id = const Uuid().v4();
    final entry = {
      'queue_id': id,
      'entity': 'setoran',
      'operation': 'update',
      'entity_id': entityId,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
    };
    list.add(entry);
    await box.put('pending', list);
    await OfflineSyncStatusService.instance.refresh();
    return id;
  }

  Future<String> queueDeleteSetoran({required int entityId}) async {
    final box = await _hive.openBox(boxName);
    final id = const Uuid().v4();
    final list = (box.get('pending') as List?) ?? [];
    list.add({
      'queue_id': id,
      'entity': 'setoran',
      'operation': 'delete',
      'entity_id': entityId,
      'created_at': DateTime.now().toIso8601String(),
    });
    await box.put('pending', list);
    await OfflineSyncStatusService.instance.refresh();
    return id;
  }

  Future<List<Map<String, dynamic>>> readPendingActions() async {
    final box = await _hive.openBox(boxName);
    final list = (box.get('pending') as List?) ?? [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> removeAction(String queueId) async {
    final box = await _hive.openBox(boxName);
    final list = (box.get('pending') as List?) ?? [];
    list.removeWhere((e) => e['queue_id'] == queueId);
    await box.put('pending', list);
    await OfflineSyncStatusService.instance.refresh();
  }

  Future<void> updateActionAttempts(String queueId, int attempts) async {
    final box = await _hive.openBox(boxName);
    final list = (box.get('pending') as List?) ?? [];

    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      if (e is Map && e['queue_id'] == queueId) {
        final updated = Map<String, dynamic>.from(e)
          ..['attempts'] = attempts
          ..['last_attempt_at'] = DateTime.now().toIso8601String();
        list[i] = updated;
        break;
      }
    }

    await box.put('pending', list);
    await OfflineSyncStatusService.instance.refresh();
  }

  Future<void> clear() async {
    final box = await _hive.openBox(boxName);
    await box.put('pending', []);
    await OfflineSyncStatusService.instance.refresh();
  }
}
