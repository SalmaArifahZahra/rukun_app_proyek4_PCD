import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_kk_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';

class KKRepository {
  final CloudKKService service;
  final AuthLocalService local;
  final CloudinaryService _cloudinary;
  final PendudukLocalCacheService cache = PendudukLocalCacheService();
  final PendudukLocalSyncService syncQueue = PendudukLocalSyncService();

  KKRepository(this.service, this.local, this._cloudinary);

  Future<List<Keluarga>> getAllKK() async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedKeluarga();
    }

    try {
      final result = await _safeCall(() => service.getAllKK(token));

      _validateStatus(result);

      final List data = result['data'] ?? [];
      final items = data.map((e) => Keluarga.fromJson(e)).toList();

      await cache.cacheKeluargaList(items);

      return items;
    } catch (e) {
      final cached = await _getCachedKeluarga();
      if (cached.isNotEmpty && _canUseCache(e)) {
        return cached;
      }

      rethrow;
    }
  }

  Future<List<Keluarga>> getKKByRT(int rtId) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(() => service.getKKByRT(rtId, token));

      _validateStatus(result);

      final List data = result['data'] ?? [];
      final items = data.map((e) => Keluarga.fromJson(e)).toList();

      await cache.cacheKeluargaList(items);

      return items;
    } catch (e) {
      final cached = await _getCachedKeluargaByRt(rtId);
      if (cached.isNotEmpty && _canUseCache(e)) {
        return cached;
      }

      rethrow;
    }
  }

  Future<Keluarga?> getKKById(int id) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(() => service.getKKById(id, token));

      _validateStatus(result);

      final data = result['data'];

      if (data == null) return null;

      final item = Keluarga.fromJson(data);
      await cache.cacheKeluargaList([item]);

      return item;
    } catch (e) {
      final cached = await _getCachedKeluargaById(id);
      if (cached != null && _canUseCache(e)) {
        return cached;
      }

      rethrow;
    }
  }

  Future<void> createKK(Keluarga kk, {String? localFotoPath}) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(() => service.createKK(kk.toJson(), token));
      _validateStatus(result);

      final data = result['data'];
      if (data is Map) {
        await cache.upsertKeluargaRaw(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      if (_canUseCache(e)) {
        await _createKKOffline(kk, localFotoPath: localFotoPath);
        return;
      }
      rethrow;
    }
  }

  Future<void> updateKK(int id, Map<String, dynamic> data) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(() => service.updateKK(id, data, token));
      _validateStatus(result);

      final resData = result['data'];
      if (resData is Map) {
        await cache.upsertKeluargaRaw(Map<String, dynamic>.from(resData));
      }
    } catch (e) {
      if (_canUseCache(e)) {
        await _updateKKOffline(id, data);
        return;
      }
      rethrow;
    }
  }

  Future<void> deleteKK(int id) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(() => service.deleteKK(id, token));
      _validateStatus(result);

      await cache.removeKeluarga(id);
    } catch (e) {
      if (_canUseCache(e)) {
        await _deleteKKOffline(id);
        return;
      }
      rethrow;
    }
  }

  Future<void> _createKKOffline(Keluarga kk, {String? localFotoPath}) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final raw = {...kk.toJson(), 'id': tempId, 'sync_status': 'pending'};

    if (localFotoPath != null) {
      raw['local_foto_path'] = localFotoPath;
    }

    await cache.upsertKeluargaRaw(raw);
    await syncQueue.queueCreateKK(tempId: tempId, payload: raw);
  }

  Future<void> _updateKKOffline(int id, Map<String, dynamic> data) async {
    final raw = {...data, 'id': id, 'sync_status': 'pending'};

    await cache.upsertKeluargaRaw(raw);
    await syncQueue.queueUpdateKK(entityId: id, payload: raw);
  }

  Future<void> _deleteKKOffline(int id) async {
    await cache.removeKeluarga(id);
    await syncQueue.queueDeleteKK(entityId: id);
  }

  Future<void> syncPending() async {
    final token = await _requireToken();
    await _syncPendingKK(token);
  }

  Future<void> _syncPendingKK(String token) async {
    final pending = await syncQueue.readPendingActions();
    if (pending.isEmpty) return;

    final tempIdMap = <int, int>{};

    for (final action in pending) {
      if (action['entity'] != 'keluarga') continue;

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
            ..remove('sync_status')
            ..remove('local_foto_path');

          // Upload foto jika ada local path
          final localFotoPath = payload['local_foto_path'] as String?;
          if (localFotoPath != null) {
            try {
              final file = File(localFotoPath);
              final uploaded = await _cloudinary.uploadFile(
                file,
                folder: 'kartukeluarga',
              );
              if (uploaded != null) {
                cleanPayload['img_referensi'] = uploaded;
              } else {
                throw Exception('Upload foto KK gagal');
              }
            } catch (e) {
              rethrow;
            }
          }

          final result = await _safeCall(
            () => service.createKK(cleanPayload, token),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            final serverRaw = Map<String, dynamic>.from(data);
            await cache.removeKeluarga(entityId);
            await cache.upsertKeluargaRaw(serverRaw);

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
            ..remove('sync_status')
            ..remove('local_foto_path');

          // Upload foto jika ada local path
          final localFotoPath = payload['local_foto_path'] as String?;
          if (localFotoPath != null) {
            try {
              final file = File(localFotoPath);
              final uploaded = await _cloudinary.uploadFile(
                file,
                folder: 'kartukeluarga',
              );
              if (uploaded != null) {
                cleanPayload['img_referensi'] = uploaded;
              }
            } catch (e) {
              debugPrint('KK foto upload during update failed: $e');
            }
          }

          final result = await _safeCall(
            () => service.updateKK(targetId, cleanPayload, token),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            await cache.upsertKeluargaRaw(Map<String, dynamic>.from(data));
          }

          await syncQueue.removeAction(queueId);
          continue;
        }

        if (operation == 'delete') {
          final result = await _safeCall(
            () => service.deleteKK(targetId, token),
          );
          _validateStatus(result);
          await cache.removeKeluarga(targetId);
          await syncQueue.removeAction(queueId);
        }
      } catch (e) {
        debugPrint('KK sync action $operation for $entityId failed: $e');
        try {
          final currentAttempts = (action['attempts'] as int?) ?? 0;
          final nextAttempts = currentAttempts + 1;
          if (nextAttempts >= 3) {
            await syncQueue.removeAction(queueId);
            debugPrint(
              'KK queue $queueId failed permanently after $nextAttempts attempts',
            );
          } else {
            await syncQueue.updateActionAttempts(queueId, nextAttempts);
            debugPrint(
              'KK queue $queueId will retry later (attempt $nextAttempts)',
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

  Future<List<Keluarga>> _getCachedKeluarga() async {
    final raw = await cache.readKeluargaRaw();
    return raw.map(Keluarga.fromJson).toList();
  }

  Future<List<Keluarga>> _getCachedKeluargaByRt(int rtId) async {
    final raw = await cache.readKeluargaRaw();
    return raw
        .where((item) => (item['rt_id'] as num?)?.toInt() == rtId)
        .map(Keluarga.fromJson)
        .toList();
  }

  Future<Keluarga?> _getCachedKeluargaById(int id) async {
    final raw = await cache.readKeluargaRaw();
    for (final item in raw) {
      if ((item['id'] as num?)?.toInt() == id) {
        return Keluarga.fromJson(item);
      }
    }

    return null;
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
