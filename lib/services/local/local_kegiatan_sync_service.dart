import 'package:hive/hive.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';
import 'package:rukun_app_proyek4/services/local/offline_sync_status_service.dart';

class KegiatanLocalSyncService {
  static const String _queueBoxName = 'offline_sync_kegiatan';

  Future<void> queueCreateKegiatan({
    required int tempId,
    required Map<String, dynamic> payload,
  }) async {
    final box = await HiveService().openBox<dynamic>(_queueBoxName);

    await box.put(tempId.toString(), {
      'queue_id': tempId.toString(),
      'operation': 'create',
      'entity': 'kegiatan',
      'entity_id': tempId,
      'payload': Map<String, dynamic>.from(payload),
      'created_at': DateTime.now().toIso8601String(),
    });

    await OfflineSyncStatusService.instance.refresh();
  }

  Future<void> queueUpdateKegiatan({
    required int entityId,
    required Map<String, dynamic> payload,
  }) async {
    final box = await HiveService().openBox<dynamic>(_queueBoxName);
    final existingCreate = _findCreateEntry(box, entityId);

    if (existingCreate != null) {
      final mergedPayload = Map<String, dynamic>.from(
        (existingCreate['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      )..addAll(payload);

      existingCreate['payload'] = mergedPayload;
      existingCreate['updated_at'] = DateTime.now().toIso8601String();
      await box.put(existingCreate['queue_id'].toString(), existingCreate);
      await OfflineSyncStatusService.instance.refresh();
      return;
    }

    final queueId = '${entityId}_${DateTime.now().microsecondsSinceEpoch}';

    await box.put(queueId, {
      'queue_id': queueId,
      'operation': 'update',
      'entity': 'kegiatan',
      'entity_id': entityId,
      'payload': Map<String, dynamic>.from(payload),
      'created_at': DateTime.now().toIso8601String(),
    });

    await OfflineSyncStatusService.instance.refresh();
  }

  Future<void> queueDeleteKegiatan({required int entityId}) async {
    final box = await HiveService().openBox<dynamic>(_queueBoxName);
    final existingCreate = _findCreateEntry(box, entityId);

    if (existingCreate != null) {
      await box.delete(existingCreate['queue_id'].toString());
      await OfflineSyncStatusService.instance.refresh();
      return;
    }

    final queueId = '${entityId}_${DateTime.now().microsecondsSinceEpoch}';

    await box.put(queueId, {
      'queue_id': queueId,
      'operation': 'delete',
      'entity': 'kegiatan',
      'entity_id': entityId,
      'payload': const <String, dynamic>{},
      'created_at': DateTime.now().toIso8601String(),
    });

    await OfflineSyncStatusService.instance.refresh();
  }

  Future<List<Map<String, dynamic>>> readPendingActions() async {
    final box = await HiveService().openBox<dynamic>(_queueBoxName);
    final actions = <Map<String, dynamic>>[];

    for (final value in box.values) {
      if (value is Map) {
        actions.add(Map<String, dynamic>.from(value));
      }
    }

    actions.sort((a, b) {
      final left =
          DateTime.tryParse(a['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final right =
          DateTime.tryParse(b['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return left.compareTo(right);
    });

    return actions;
  }

  Future<void> removeAction(String queueId) async {
    final box = await HiveService().openBox<dynamic>(_queueBoxName);
    await box.delete(queueId);

    await OfflineSyncStatusService.instance.refresh();
  }

  Future<void> updateActionAttempts(
    String queueId,
    int attempts,
  ) async {
    final box = await HiveService().openBox<dynamic>(_queueBoxName);
    final raw = box.get(queueId);
    if (raw is Map) {
      final action = Map<String, dynamic>.from(raw);
      action['attempts'] = attempts;
      action['last_attempt_at'] = DateTime.now().toIso8601String();
      await box.put(queueId, action);
    }
  }

  Map<String, dynamic>? _findCreateEntry(Box<dynamic> box, int entityId) {
    for (final value in box.values) {
      if (value is Map) {
        final mapped = Map<String, dynamic>.from(value);
        if (mapped['entity'] == 'kegiatan' &&
            mapped['operation'] == 'create' &&
            (mapped['entity_id'] as num?)?.toInt() == entityId) {
          return mapped;
        }
      }
    }

    return null;
  }
}
