import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_kegiatan_service.dart';
import 'package:rukun_app_proyek4/services/local/local_kegiatan_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_kegiatan_sync_service.dart';

class KegiatanRepository {
  final CloudKegiatanService service;
  final AuthLocalService local;
  final KegiatanLocalCacheService cache = KegiatanLocalCacheService();
  final KegiatanLocalSyncService syncQueue = KegiatanLocalSyncService();

  KegiatanRepository(this.service, this.local);

  Future<List<Kegiatan>> getAllKegiatan() async {
    final token = await local.getToken();

    if (token == null) {
      final cached = await cache.readKegiatanRaw();
      return cached.map(Kegiatan.fromJson).toList();
    }

    try {
      final result = await _safeCall(
        () => service.getAllKegiatan(token),
      );

      _validateStatus(result);

      final List data = result['data'] ?? [];
      final rawItems = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await cache.cacheKegiatanRawList(rawItems);

      return rawItems.map(Kegiatan.fromJson).toList();
    } catch (e) {
      if (_canUseCache(e)) {
        final cached = await cache.readKegiatanRaw();
        return cached.map(Kegiatan.fromJson).toList();
      }
      rethrow;
    }
  }

  Future<Kegiatan?> getKegiatanById(int id) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(
        () => service.getKegiatanById(id, token),
      );

      _validateStatus(result);

      final data = result['data'];

      if (data == null) return null;

      final item = Kegiatan.fromJson(data);
      await cache.upsertKegiatanRaw(Map<String, dynamic>.from(data));

      return item;
    } catch (e) {
      if (_canUseCache(e)) {
        final cached = await cache.readKegiatanRaw();
        for (final item in cached) {
          if ((item['id'] as num?)?.toInt() == id) {
            return Kegiatan.fromJson(item);
          }
        }
      }
      rethrow;
    }
  }

  Future<List<Kegiatan>> getKegiatanByRW(int rwId) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(
        () => service.getKegiatanByRW(rwId, token),
      );

      _validateStatus(result);

      final List data = result['data'] ?? [];
      final rawItems = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await cache.cacheKegiatanRawList(rawItems);

      return rawItems.map(Kegiatan.fromJson).toList();
    } catch (e) {
      if (_canUseCache(e)) {
        final cached = await cache.readKegiatanRaw();
        return cached
            .where((item) => (item['rw_id'] as num?)?.toInt() == rwId)
            .map(Kegiatan.fromJson)
            .toList();
      }
      rethrow;
    }
  }

  Future<bool> createKegiatan(Kegiatan kegiatan) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(
        () => service.createKegiatan(kegiatan.toJson(), token),
      );

      _validateStatus(result);

      final data = result['data'];
      if (data is Map) {
        await cache.upsertKegiatanRaw(Map<String, dynamic>.from(data));
      }

      return true;
    } catch (e) {
      if (_canUseCache(e)) {
        await _createKegiatanOffline(kegiatan);
        return true;
      }
      rethrow;
    }
  }

  Future<void> updateKegiatan(int id, Map<String, dynamic> data) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(
        () => service.updateKegiatan(id, data, token),
      );

      _validateStatus(result);

      final resData = result['data'];
      if (resData is Map) {
        await cache.upsertKegiatanRaw(Map<String, dynamic>.from(resData));
      }
    } catch (e) {
      if (_canUseCache(e)) {
        await _updateKegiatanOffline(id, data);
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteKegiatan(int id) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(
        () => service.deleteKegiatan(id, token),
      );

      _validateStatus(result);

      await cache.removeKegiatan(id);
    } catch (e) {
      if (_canUseCache(e)) {
        await _deleteKegiatanOffline(id);
        return;
      }
      rethrow;
    }
  }

  Future<void> _createKegiatanOffline(Kegiatan kegiatan) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final raw = {...kegiatan.toJson(), 'id': tempId, 'sync_status': 'pending'};

    await cache.upsertKegiatanRaw(raw);
    await syncQueue.queueCreateKegiatan(tempId: tempId, payload: raw);
  }

  Future<void> _updateKegiatanOffline(int id, Map<String, dynamic> data) async {
    final raw = {...data, 'id': id, 'sync_status': 'pending'};

    await cache.upsertKegiatanRaw(raw);
    await syncQueue.queueUpdateKegiatan(entityId: id, payload: raw);
  }

  Future<void> _deleteKegiatanOffline(int id) async {
    await cache.removeKegiatan(id);
    await syncQueue.queueDeleteKegiatan(entityId: id);
  }

  Future<void> syncPending() async {
    final token = await _requireToken();
    await _syncPendingKegiatan(token);
  }

  Future<void> _syncPendingKegiatan(String token) async {
    final pending = await syncQueue.readPendingActions();
    if (pending.isEmpty) return;

    final tempIdMap = <int, int>{};

    for (final action in pending) {
      if (action['entity'] != 'kegiatan') continue;

      final queueId = action['queue_id'] as String?;
      if (queueId == null) continue;

      final operation = action['operation'] as String?;
      final entityId = (action['entity_id'] as num?)?.toInt();
      if (entityId == null) continue;

      final payload = Map<String, dynamic>.from(
        (action['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      );

      try {
        if (operation == 'create') {
          final cleanPayload = Map<String, dynamic>.from(payload)
            ..remove('id')
            ..remove('sync_status');

          final result = await _safeCall(
            () => service.createKegiatan(cleanPayload, token),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            final serverRaw = Map<String, dynamic>.from(data);
            await cache.removeKegiatan(entityId);
            await cache.upsertKegiatanRaw(serverRaw);

            final serverId = (serverRaw['id'] as num?)?.toInt();
            if (serverId != null) tempIdMap[entityId] = serverId;
          }

          await syncQueue.removeAction(queueId);
          continue;
        }

        final targetId = tempIdMap[entityId] ?? entityId;

        if (operation == 'update') {
          final cleanPayload = Map<String, dynamic>.from(payload)
            ..remove('id')
            ..remove('sync_status');

          final result = await _safeCall(
            () => service.updateKegiatan(targetId, cleanPayload, token),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            await cache.upsertKegiatanRaw(Map<String, dynamic>.from(data));
          }

          await syncQueue.removeAction(queueId);
          continue;
        }

        if (operation == 'delete') {
          final result = await _safeCall(
            () => service.deleteKegiatan(targetId, token),
          );
          _validateStatus(result);
          await cache.removeKegiatan(targetId);
          await syncQueue.removeAction(queueId);
        }
      } catch (e) {
        debugPrint('Kegiatan sync action $operation for $entityId failed: $e');
        try {
          final currentAttempts = (action['attempts'] as int?) ?? 0;
          final nextAttempts = currentAttempts + 1;
          if (nextAttempts >= 3) {
            await syncQueue.removeAction(queueId);
            debugPrint(
              'Kegiatan queue $queueId failed permanently after $nextAttempts attempts',
            );
          } else {
            await syncQueue.updateActionAttempts(queueId, nextAttempts);
            debugPrint(
              'Kegiatan queue $queueId will retry later (attempt $nextAttempts)',
            );
          }
        } catch (_) {}
        continue;
      }
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
    final meta = result['meta'];

    if (meta != null && meta['code'] != 200) {
      throw Exception(meta['message'] ?? "Unknown error");
    }

    if (result['status'] != null && result['status'] != 'success') {
      throw Exception(result['message'] ?? "Unknown error");
    }
  }
}
