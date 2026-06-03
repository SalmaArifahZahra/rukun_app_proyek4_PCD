import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_warga_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_sync_service.dart';

class WargaRepository {
  final CloudWargaService service;
  final AuthLocalService local;
  final PendudukLocalCacheService cache = PendudukLocalCacheService();
  final PendudukLocalSyncService syncQueue = PendudukLocalSyncService();

  WargaRepository(this.service, this.local);

  Future<List<Warga>> getAllWarga() async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedWarga();
    }

    try {
      await _syncPendingWarga(token);

      final result = await _safeCall(() => service.getAllWarga(token));

      _validateStatus(result);

      final rawItems = _extractRawWargaList(result['data']);
      await cache.cacheWargaRawList(rawItems);

      final items = await _hydrateWargaList(rawItems);

      return items;
    } catch (e) {
      final cached = await _getCachedWarga();
      if (cached.isNotEmpty && _canUseCache(e)) {
        return cached;
      }

      rethrow;
    }
  }

  Future<Warga?> getWargaById(int id) async {
    try {
      final token = await _requireToken();
      await _syncPendingWarga(token);

      final result = await _safeCall(() => service.getWargaById(id, token));

      _validateStatus(result);

      final data = result['data'];
      if (data == null) return null;

      final rawItem = _normalizeWargaMap(data);
      await cache.upsertWargaRaw(rawItem);

      final item = Warga.fromJson(rawItem);

      return item;
    } catch (e) {
      final cached = await _getCachedWargaById(id);
      if (cached != null && _canUseCache(e)) {
        return cached;
      }

      rethrow;
    }
  }

  Future<List<Warga>> getWargaByKeluarga(int keluargaId) async {
    try {
      final token = await _requireToken();
      await _syncPendingWarga(token);

      final result = await _safeCall(
        () => service.getWargaByKeluarga(keluargaId, token),
      );

      _validateStatus(result);

      final rawItems = _extractRawWargaList(result['data']);
      await cache.cacheWargaRawList(rawItems);

      final items = await _hydrateWargaList(rawItems);

      return items;
    } catch (e) {
      final cached = await _getCachedWargaByKeluarga(keluargaId);
      if (cached.isNotEmpty && _canUseCache(e)) {
        return cached;
      }

      rethrow;
    }
  }

  Future<void> createWarga(Warga warga) async {
    try {
      final token = await _requireToken();
      await _syncPendingWarga(token);

      final result = await _safeCall(
        () => service.createWarga(warga.toJson(), token),
      );

      _validateStatus(result);

      final data = result['data'];
      if (data is Map) {
        await cache.upsertWargaRaw(_normalizeWargaMap(data));
      } else {
        await cache.upsertWargaRaw(_normalizeWargaMap(warga.toJson()));
      }
    } catch (e) {
      if (_canUseCache(e)) {
        await _createWargaOffline(warga);
        return;
      }

      rethrow;
    }
  }

  Future<void> updateWarga(int id, Warga warga) async {
    try {
      final token = await _requireToken();
      await _syncPendingWarga(token);

      final result = await _safeCall(
        () => service.updateWarga(id, warga.toJson(), token),
      );

      _validateStatus(result);

      final data = result['data'];
      if (data is Map) {
        await cache.upsertWargaRaw(_normalizeWargaMap(data));
      } else {
        await cache.upsertWargaRaw(
          _normalizeWargaMap({...warga.toJson(), 'id': id}),
        );
      }
    } catch (e) {
      if (_canUseCache(e)) {
        await _updateWargaOffline(id, warga);
        return;
      }

      rethrow;
    }
  }

  Future<void> deleteWarga(int id) async {
    try {
      final token = await _requireToken();
      await _syncPendingWarga(token);

      final result = await _safeCall(() => service.deleteWarga(id, token));

      _validateStatus(result);

      await cache.removeWarga(id);
    } catch (e) {
      if (_canUseCache(e)) {
        await _deleteWargaOffline(id);
        return;
      }

      rethrow;
    }
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

  Future<List<Warga>> _getCachedWarga() async {
    final raw = await cache.readWargaRaw();
    return _hydrateWargaList(raw);
  }

  Future<Warga?> _getCachedWargaById(int id) async {
    final raw = await cache.readWargaRaw();

    for (final item in raw) {
      if ((item['id'] as num?)?.toInt() == id) {
        return Warga.fromJson(await _normalizeCachedWarga(item));
      }
    }

    return null;
  }

  Future<List<Warga>> _getCachedWargaByKeluarga(int keluargaId) async {
    final raw = await cache.readWargaRaw();
    final filtered = raw
        .where((item) => (item['keluarga_id'] as num?)?.toInt() == keluargaId)
        .toList();

    return _hydrateWargaList(filtered);
  }

  Future<List<Warga>> _hydrateWargaList(List<Map<String, dynamic>> raw) async {
    final keluargaMap = await _getCachedKeluargaMap();
    return raw
        .map((item) => Warga.fromJson(_normalizeWargaMap(item, keluargaMap)))
        .toList();
  }

  List<Map<String, dynamic>> _extractRawWargaList(dynamic data) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => _normalizeWargaMap(item))
        .toList();
  }

  Future<void> _createWargaOffline(Warga warga) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final raw = _prepareOfflinePayload(warga.toJson(), tempId);

    await cache.upsertWargaRaw(raw);
    await syncQueue.queueCreateWarga(tempId: tempId, payload: raw);
  }

  Future<void> _updateWargaOffline(int id, Warga warga) async {
    final raw = _prepareOfflinePayload({...warga.toJson(), 'id': id}, id);

    await cache.upsertWargaRaw(raw);
    await syncQueue.queueUpdateWarga(entityId: id, payload: raw);
  }

  Future<void> _deleteWargaOffline(int id) async {
    await cache.removeWarga(id);
    await syncQueue.queueDeleteWarga(entityId: id);
  }

  Future<void> _syncPendingWarga(String token) async {
    final pending = await syncQueue.readPendingActions();
    if (pending.isEmpty) {
      return;
    }

    final tempIdMap = <int, int>{};

    for (final action in pending) {
      if (action['entity'] != 'warga') {
        continue;
      }

      final queueId = action['queue_id'] as String?;
      if (queueId == null) {
        continue;
      }

      final operation = action['operation'] as String?;
      final entityId = (action['entity_id'] as num?)?.toInt();
      if (entityId == null) {
        continue;
      }

      final payload = Map<String, dynamic>.from(
        (action['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      );

      try {
        if (operation == 'create') {
          final cleanPayload = _stripSyncFields(payload)..remove('id');

          final result = await _safeCall(
            () => service.createWarga(cleanPayload, token),
          );

          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            final serverRaw = _normalizeWargaMap(data);
            await cache.removeWarga(entityId);
            await cache.upsertWargaRaw(serverRaw);

            final serverId = (serverRaw['id'] as num?)?.toInt();
            if (serverId != null) {
              tempIdMap[entityId] = serverId;
            }
          } else {
            await cache.removeWarga(entityId);
          }

          await syncQueue.removeAction(queueId);
          continue;
        }

        final targetId = tempIdMap[entityId] ?? entityId;

        if (operation == 'update') {
          final cleanPayload = _stripSyncFields(payload)..remove('id');
          final result = await _safeCall(
            () => service.updateWarga(targetId, cleanPayload, token),
          );

          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            await cache.upsertWargaRaw(_normalizeWargaMap(data));
          } else {
            await cache.upsertWargaRaw({...cleanPayload, 'id': targetId});
          }

          await syncQueue.removeAction(queueId);
          continue;
        }

        if (operation == 'delete') {
          final result = await _safeCall(
            () => service.deleteWarga(targetId, token),
          );

          _validateStatus(result);
          await cache.removeWarga(targetId);
          await syncQueue.removeAction(queueId);
        }
      } catch (e) {
        debugPrint('Warga sync action $operation for $entityId failed: $e');
        try {
          final currentAttempts = (action['attempts'] as int?) ?? 0;
          final nextAttempts = currentAttempts + 1;
          if (nextAttempts >= 3) {
            await syncQueue.removeAction(queueId);
            debugPrint(
              'Warga queue $queueId failed permanently after $nextAttempts attempts',
            );
          } else {
            await syncQueue.updateActionAttempts(queueId, nextAttempts);
            debugPrint(
              'Warga queue $queueId will retry later (attempt $nextAttempts)',
            );
          }
        } catch (_) {}
        continue;
      }
    }
  }

  /// Public wrapper to trigger pending sync (used by SyncCoordinator)
  Future<void> syncPending() async {
    final token = await _requireToken();
    await _syncPendingWarga(token);
  }

  Map<String, dynamic> _prepareOfflinePayload(
    Map<String, dynamic> raw,
    int id,
  ) {
    return {
      ...raw,
      'id': id,
      'sync_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _stripSyncFields(Map<String, dynamic> raw) {
    final result = Map<String, dynamic>.from(raw);
    result.remove('sync_status');
    result.remove('queue_id');
    result.remove('created_at');
    result.remove('updated_at');
    result.remove('entity');
    result.remove('entity_id');
    result.remove('operation');
    result.remove('local_queue_id');
    return result;
  }

  Map<String, dynamic> _normalizeWargaMap(
    dynamic raw, [
    Map<int, Keluarga>? keluargaMap,
  ]) {
    final source = Map<String, dynamic>.from(raw as Map);
    final keluargaId = (source['keluarga_id'] as num?)?.toInt();
    final keluarga = keluargaMap?[keluargaId];

    if (keluarga != null) {
      source['keluarga'] = keluarga.toJson();
    }

    return source;
  }

  Future<Map<String, dynamic>> _normalizeCachedWarga(
    Map<String, dynamic> raw,
  ) async {
    final keluargaMap = await _getCachedKeluargaMap();
    return _normalizeWargaMap(raw, keluargaMap);
  }

  Future<Map<int, Keluarga>> _getCachedKeluargaMap() async {
    final raw = await cache.readKeluargaRaw();
    final result = <int, Keluarga>{};

    for (final item in raw) {
      final id = (item['id'] as num?)?.toInt();
      if (id == null) {
        continue;
      }

      result[id] = Keluarga.fromJson(item);
    }

    return result;
  }

  bool _canUseCache(Object error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.unknown => true,
        _ => false,
      };
    }

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable');
  }

  void _validateStatus(Map<String, dynamic> result) {
    if (result['status'] != 'success') {
      throw Exception(result['message'] ?? "Unknown error");
    }
  }
}
