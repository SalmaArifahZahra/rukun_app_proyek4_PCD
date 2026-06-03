import 'package:dio/dio.dart';
import 'package:rukun_app_proyek4/models/setoran_iuran_rt_model.dart';
import 'dart:io';

import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_setoran_iuran_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_sync_service.dart';
import 'package:rukun_app_proyek4/services/local/navigation_service.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class SetoranIuranRtRepository {
  final CloudSetoranIuranRtService service;
  final AuthLocalService local;

  SetoranIuranRtRepository(this.service, this.local, this.cloudinary);

  final CloudinaryService cloudinary;

  final SetoranIuranLocalCacheService cache = SetoranIuranLocalCacheService();
  final SetoranIuranLocalSyncService syncQueue = SetoranIuranLocalSyncService();

  Future<List<SetoranIuranRt>> getAllSetoran() async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedSetoran();
    }

    try {
      await syncPending();

      final result = await _safeCall(() => service.getAllSetoran(token));

      _validateStatus(result);

      final List data = result['data'] ?? [];
      final raw = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await cache.cacheSetoranRawList(raw);

      return raw.map((e) => SetoranIuranRt.fromJson(e)).toList();
    } catch (e) {
      // fallback to cache if network error
      final cached = await _getCachedSetoran();
      if (cached.isNotEmpty && _canUseCache(e)) return cached;
      rethrow;
    }
  }

  Future<SetoranIuranRt?> getSetoranById(int id) async {
    try {
      final token = await _requireToken();
      await syncPending();

      final result = await _safeCall(() => service.getSetoranById(id, token));

      _validateStatus(result);

      final data = result['data'];

      if (data == null) return null;

      final raw = Map<String, dynamic>.from(data as Map);
      await cache.upsertSetoranRaw(raw);

      return SetoranIuranRt.fromJson(raw);
    } catch (e) {
      final cached = await _getCachedSetoranById(id);
      if (cached != null && _canUseCache(e)) return cached;

      rethrow;
    }
  }

  Future<List<SetoranIuranRt>> getSetoranByRT(int rtId) async {
    final token = await _requireToken();

    final result = await _safeCall(() => service.getSetoranByRT(rtId, token));

    _validateStatus(result);

    final List data = result['data'] ?? [];

    return data.map((e) => SetoranIuranRt.fromJson(e)).toList();
  }

  Future<List<SetoranIuranRt>> getSetoranByIuranRT(
    int iuranId,
    int rtId,
  ) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.getSetoranByIuranRT(iuranId, rtId, token),
    );

    _validateStatus(result);

    final List data = result['data'] ?? [];

    return data.map((e) => SetoranIuranRt.fromJson(e)).toList();
  }

  Future<SetoranIuranRt?> getSetoranByPeriode(
    int iuranId,
    int rtId,
    String periode,
  ) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.getSetoranByPeriode(iuranId, rtId, periode, token),
    );

    _validateStatus(result);

    final data = result['data'];

    if (data == null) {
      return null;
    }

    return SetoranIuranRt.fromJson(data);
  }

  Future<void> createSetoran(
    SetoranIuranRt setoran, {
    String? localDocumentPath,
  }) async {
    try {
      final token = await _requireToken();
      await syncPending();

      final result = await _safeCall(
        () => service.createSetoran(setoran.toJson(), token),
      );

      _validateStatus(result);
    } catch (e) {
      if (_canUseCache(e)) {
        await _createSetoranOffline(
          setoran,
          localDocumentPath: localDocumentPath,
        );
        return;
      }

      rethrow;
    }
  }

  Future<void> updateSetoran(int id, SetoranIuranRt setoran) async {
    try {
      final token = await _requireToken();
      await syncPending();

      final result = await _safeCall(
        () => service.updateSetoran(id, setoran.toJson(), token),
      );

      _validateStatus(result);
    } catch (e) {
      if (_canUseCache(e)) {
        await _updateSetoranOffline(id, setoran);
        return;
      }

      rethrow;
    }
  }

  Future<void> approveSetoran(int id) async {
    final token = await _requireToken();

    final result = await _safeCall(() => service.approveSetoran(id, token));

    _validateStatus(result);
  }

  Future<void> rejectSetoran(int id, String catatan) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.rejectSetoran(id, catatan, token),
    );

    _validateStatus(result);
  }

  Future<void> deleteSetoran(int id) async {
    try {
      final token = await _requireToken();
      await syncPending();

      final result = await _safeCall(() => service.deleteSetoran(id, token));

      _validateStatus(result);
    } catch (e) {
      if (_canUseCache(e)) {
        await _deleteSetoranOffline(id);
        return;
      }

      rethrow;
    }
  }

  Future<List<SetoranIuranRt>> _getCachedSetoran() async {
    final raw = await cache.readSetoranRaw();
    return raw.map((e) => SetoranIuranRt.fromJson(e)).toList();
  }

  Future<SetoranIuranRt?> _getCachedSetoranById(int id) async {
    final raw = await cache.readSetoranRaw();
    for (final item in raw) {
      if ((item['id'] as num?)?.toInt() == id) {
        return SetoranIuranRt.fromJson(item);
      }
    }

    return null;
  }

  /// Return raw cached setoran by periode if exists (including pending local items)
  Future<Map<String, dynamic>?> getCachedSetoranRawByPeriode(
    int iuranId,
    int rtId,
    String periode,
  ) async {
    final raw = await cache.readSetoranRaw();

    for (final item in raw) {
      final itemIuran = (item['iuran_id'] as num?)?.toInt();
      final itemRt = (item['rt_id'] as num?)?.toInt();
      final itemPeriode = (item['periode_bulan'] as String?);

      if (itemIuran == iuranId && itemRt == rtId && itemPeriode == periode) {
        return Map<String, dynamic>.from(item);
      }
    }

    return null;
  }

  Future<void> _createSetoranOffline(
    SetoranIuranRt setoran, {
    String? localDocumentPath,
  }) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final raw = _prepareOfflinePayload(setoran.toJson(), tempId);

    if (localDocumentPath != null) {
      raw['local_document_path'] = localDocumentPath;
    }

    await cache.upsertSetoranRaw(raw);
    await syncQueue.queueCreateSetoran(tempId: tempId, payload: raw);
  }

  Future<void> _updateSetoranOffline(int id, SetoranIuranRt setoran) async {
    final raw = _prepareOfflinePayload({...setoran.toJson(), 'id': id}, id);
    await cache.upsertSetoranRaw(raw);
    await syncQueue.queueUpdateSetoran(entityId: id, payload: raw);
  }

  Future<void> _deleteSetoranOffline(int id) async {
    await cache.removeSetoran(id);
    await syncQueue.queueDeleteSetoran(entityId: id);
  }

  Future<void> _syncPendingSetoran(String token) async {
    final pending = await syncQueue.readPendingActions();
    if (pending.isEmpty) return;

    final tempIdMap = <int, int>{};

    for (final action in pending) {
      if (action['entity'] != 'setoran') continue;

      final queueId = action['queue_id'] as String?;
      if (queueId == null) continue;

      final operation = action['operation'] as String?;
      final entityId = (action['entity_id'] as num?)?.toInt();
      if (entityId == null) continue;

      final payload = Map<String, dynamic>.from(
        (action['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      );

      // backoff / attempts handling
      final attempts = (action['attempts'] as int?) ?? 0;
      final lastAttemptStr = action['last_attempt_at'] as String?;
      final lastAttempt = lastAttemptStr != null
          ? DateTime.tryParse(lastAttemptStr)
          : null;
      final base = 2;
      final backoff = min(60, pow(2, attempts) * base).toInt();
      if (lastAttempt != null) {
        final elapsed = DateTime.now().difference(lastAttempt).inSeconds;
        if (elapsed < backoff) {
          debugPrint('Skipping queue $queueId due backoff ($elapsed<$backoff)');
          continue;
        }
      }

      try {
        if (operation == 'create') {
          final cleanPayload = _stripSyncFields(payload)..remove('id');

          // If there is a local file path, attempt upload first
          final localPath = payload['local_document_path'] as String?;
          if (localPath != null) {
            try {
              final file = File(localPath);
              final uploaded = await cloudinary.uploadFile(
                file,
                folder: 'setoran_iuran_rt',
              );
              if (uploaded != null) {
                cleanPayload['document_ref'] = uploaded;
              } else {
                // upload failed; will be caught by outer try-catch for retry
                throw Exception('Upload bukti gagal');
              }
            } catch (e) {
              rethrow;
            }
          }

          final result = await _safeCall(
            () => service.createSetoran(cleanPayload, token),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            final serverRaw = Map<String, dynamic>.from(data);
            await cache.removeSetoran(entityId);
            await cache.upsertSetoranRaw(serverRaw);

            final serverId = (serverRaw['id'] as num?)?.toInt();
            if (serverId != null) tempIdMap[entityId] = serverId;
          }

          await syncQueue.removeAction(queueId);
          final ctx = NavigationService.context;
          debugPrint('Setoran queue $queueId synced');
          if (ctx != null)
            NotificationUtils.showSuccess(ctx, 'Setoran berhasil disinkron');
          continue;
        }

        final targetId = tempIdMap[entityId] ?? entityId;

        if (operation == 'update') {
          final cleanPayload = _stripSyncFields(payload);
          final result = await _safeCall(
            () => service.updateSetoran(targetId, cleanPayload, token),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            await cache.upsertSetoranRaw(Map<String, dynamic>.from(data));
          } else {
            await cache.upsertSetoranRaw({...cleanPayload, 'id': targetId});
          }

          await syncQueue.removeAction(queueId);
          final ctx = NavigationService.context;
          debugPrint('Setoran update queue $queueId synced');
          if (ctx != null)
            NotificationUtils.showSuccess(
              ctx,
              'Perubahan setoran berhasil disinkron',
            );
          continue;
        }

        if (operation == 'delete') {
          final result = await _safeCall(
            () => service.deleteSetoran(targetId, token),
          );
          _validateStatus(result);
          await cache.removeSetoran(targetId);
          await syncQueue.removeAction(queueId);
          final ctx = NavigationService.context;
          debugPrint('Setoran delete queue $queueId synced');
          if (ctx != null)
            NotificationUtils.showSuccess(ctx, 'Setoran dihapus dari server');
        }
      } catch (_) {
        // increment attempts and backoff
        try {
          final currentAttempts = (action['attempts'] as int?) ?? 0;
          final nextAttempts = currentAttempts + 1;
          if (nextAttempts >= 3) {
            // give up permanently
            await syncQueue.removeAction(queueId);
            final ctx = NavigationService.context;
            debugPrint(
              'Queue $queueId failed permanently after $nextAttempts attempts',
            );
            if (ctx != null)
              NotificationUtils.showError(
                ctx,
                'Sinkronisasi gagal untuk sebuah item (dihapus dari antrean)',
              );
          } else {
            await syncQueue.updateActionAttempts(queueId, nextAttempts);
            debugPrint(
              'Queue $queueId will retry later (attempt $nextAttempts)',
            );
          }
        } catch (e) {
          debugPrint('Failed to update attempts for $queueId: $e');
        }

        continue;
      }
    }
  }

  /// Public wrapper for background coordinator
  Future<void> syncPending() async {
    final token = await _requireToken();
    await _syncPendingSetoran(token);
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

  void _validateStatus(Map<String, dynamic> result) {
    if (result['status'] != 'success') {
      throw Exception(result['message'] ?? "Unknown error");
    }
  }
}
