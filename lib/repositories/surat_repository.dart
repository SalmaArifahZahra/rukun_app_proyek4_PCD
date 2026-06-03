import 'package:dio/dio.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_surat_service.dart';
import 'dart:io';

import 'package:rukun_app_proyek4/services/local/local_surat_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_surat_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/services/local/navigation_service.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class SuratRepository {
  final CloudSuratService service;
  final AuthLocalService local;
  final SuratLocalCacheService _cache = SuratLocalCacheService();
  final SuratLocalSyncService _sync = SuratLocalSyncService();
  final CloudinaryService _cloudinary;

  SuratRepository(this.service, this.local, this._cloudinary);

  Future<List<PengajuanSurat>> getAllSurat() async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedSuratAll();
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(() => service.getAllSurat(token));
      _validateStatus(result);

      final items = _mapSuratList(result['data']);
      await _cache.cacheSuratAllList(items);

      return items;
    } catch (e) {
      if (_canUseCache(e)) {
        return _getCachedSuratAll();
      }

      rethrow;
    }
  }

  Future<List<PengajuanSurat>> getSuratSaya() async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedSuratSaya();
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(() => service.getSuratSaya(token));
      _validateStatus(result);

      final items = _mapSuratList(result['data']);
      await _cache.cacheSuratSayaList(items);
      await _cache.cacheSuratAllList(items);

      return items;
    } catch (e) {
      if (_canUseCache(e)) {
        return _getCachedSuratSaya();
      }

      rethrow;
    }
  }

  Future<PengajuanSurat?> getSuratById(int id) async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedSuratById(id);
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(() => service.getSuratById(id, token));
      _validateStatus(result);

      final data = result['data'];
      if (data == null) return null;

      final surat = PengajuanSurat.fromJson(Map<String, dynamic>.from(data));
      await _cache.upsertSuratAllRaw(surat.toJson());

      return surat;
    } catch (e) {
      if (_canUseCache(e)) {
        return _getCachedSuratById(id);
      }

      rethrow;
    }
  }

  Future<List<PengajuanSurat>> getSuratByRt(int rtId) async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedSuratByRt(rtId);
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(() => service.getSuratByRt(rtId, token));
      _validateStatus(result);

      final items = _mapSuratList(result['data']);
      await _cache.cacheSuratAllList(items);
      await _cache.cacheSuratRtList(rtId, items);

      return items;
    } catch (e) {
      if (_canUseCache(e)) {
        return _getCachedSuratByRt(rtId);
      }

      rethrow;
    }
  }

  Future<List<PengajuanSurat>> getSuratByRw(int rwId) async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedSuratByRw(rwId);
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(() => service.getSuratByRw(rwId, token));
      _validateStatus(result);

      final items = _mapSuratList(result['data']);
      await _cache.cacheSuratAllList(items);
      await _cache.cacheSuratRwList(rwId, items);

      return items;
    } catch (e) {
      if (_canUseCache(e)) {
        return _getCachedSuratByRw(rwId);
      }

      rethrow;
    }
  }

  Future<bool> createSurat(PengajuanSurat surat) async {
    final token = await local.getToken();

    if (token == null) {
      await _queueLocalCreate(surat);
      return true;
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(
        () => service.createSurat(surat.toJson(), token),
      );

      _validateStatus(result);

      final created = _normalizeCreatedSurat(result['data'], fallback: surat);

      await _upsertCreatedSurat(created, cacheSaya: true);

      return true;
    } catch (e) {
      if (_canUseCache(e)) {
        await _queueLocalCreate(surat);
        return true;
      }

      rethrow;
    }
  }

  Future<void> updateSurat(int id, Map<String, dynamic> data) async {
    final token = await local.getToken();

    if (token == null) {
      await _queueLocalUpdate(id, data);
      await _updateCachedSurat(id, data, syncStatus: 'pending');
      return;
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(
        () => service.updateSurat(id, data, token),
      );
      _validateStatus(result);

      await _updateCachedSurat(id, data, syncStatus: 'synced');
    } catch (e) {
      if (_canUseCache(e)) {
        await _queueLocalUpdate(id, data);
        await _updateCachedSurat(id, data, syncStatus: 'pending');
        return;
      }

      rethrow;
    }
  }

  Future<void> deleteSurat(int id) async {
    final token = await local.getToken();

    if (token == null) {
      await _queueLocalDelete(id);
      await _removeCachedSurat(id);
      return;
    }

    try {
      await _processPendingQueue(token);

      final result = await _safeCall(() => service.deleteSurat(id, token));
      _validateStatus(result);

      await _removeCachedSurat(id);
    } catch (e) {
      if (_canUseCache(e)) {
        await _queueLocalDelete(id);
        await _removeCachedSurat(id);
        return;
      }

      rethrow;
    }
  }

  Future<void> _processPendingQueue(String token) async {
    final actions = await _sync.readPendingActions();
    final tempIdMap = <int, int?>{};

    for (final action in actions) {
      final queueId = action['queue_id']?.toString();
      final operation = action['operation']?.toString();
      final entityId = (action['entity_id'] as num?)?.toInt();
      final payload = Map<String, dynamic>.from(
        (action['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      );

      // attempts/backoff
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
          debugPrint(
            'Skipping surat queue $queueId due backoff ($elapsed<$backoff)',
          );
          continue;
        }
      }

      try {
        if (operation == 'create') {
          final tempId =
              (payload['client_temp_id'] as num?)?.toInt() ?? entityId;
          final cleanPayload = Map<String, dynamic>.from(payload)
            ..remove('queue_id')
            ..remove('operation')
            ..remove('entity')
            ..remove('entity_id')
            ..remove('created_at')
            ..remove('updated_at')
            ..remove('sync_status')
            ..remove('client_temp_id')
            ..remove('id');

          final result = await _safeCall(
            () => service.createSurat(cleanPayload, token),
          );

          _validateStatus(result);

          final created = _normalizeCreatedSurat(
            result['data'],
            fallback: PengajuanSurat.fromJson(payload),
            entityIdFallback: entityId,
            clientTempId: tempId,
          );

          await _upsertCreatedSurat(
            created,
            cacheSaya: true,
            previousTempId: tempId,
          );

          if (created.id != null && tempId != null) {
            tempIdMap[tempId] = created.id;
          }

          // success notification
          final ctx = NavigationService.context;
          debugPrint('Surat create queue ${queueId ?? tempId} synced');
          if (ctx != null)
            NotificationUtils.showSuccess(ctx, 'Surat berhasil disinkron');
        } else if (operation == 'update' && entityId != null) {
          final result = await _safeCall(
            () => service.updateSurat(entityId, payload, token),
          );

          _validateStatus(result);
          await _updateCachedSurat(entityId, payload, syncStatus: 'synced');
          final ctx = NavigationService.context;
          debugPrint('Surat update queue $queueId synced');
          if (ctx != null)
            NotificationUtils.showSuccess(
              ctx,
              'Perubahan surat berhasil disinkron',
            );
        } else if (operation == 'delete' && entityId != null) {
          final result = await _safeCall(
            () => service.deleteSurat(entityId, token),
          );

          _validateStatus(result);
          await _removeCachedSurat(entityId);
          final ctx = NavigationService.context;
          debugPrint('Surat delete queue $queueId synced');
          if (ctx != null)
            NotificationUtils.showSuccess(ctx, 'Surat terhapus dari server');
        }
        // handle file upload queued actions
        else if (operation == 'file_upload' && entityId != null) {
          final localPath = payload['local_file_path'] as String?;
          final uploadType = payload['upload_type'] as String?;

          final int entId = entityId;
          final targetId = tempIdMap[entId] ?? entId;
          if (localPath == null || uploadType == null) {
            // malformed payload
          } else if (targetId <= 0) {
            // not yet resolved, skip for now
          } else {
            try {
              final file = File(localPath);
              final url = await _cloudinary.uploadFile(
                file,
                folder: 'surat/pengajuan/$targetId',
              );

              if (url != null) {
                final Map<String, dynamic> body = {};
                if (uploadType == 'draft') {
                  body['status'] = 'Disetujui';
                  body['doc_referensi'] = url;
                  body['is_signed'] = false;
                  if (payload['disetujui_oleh'] != null) {
                    body['disetujui_oleh'] = payload['disetujui_oleh'];
                  }
                } else if (uploadType == 'signed') {
                  body['status'] = 'Selesai';
                  body['doc_referensi'] = url;
                  body['is_signed'] = true;
                }

                final upd = await _safeCall(
                  () => service.updateSurat(targetId, body, token),
                );
                _validateStatus(upd);
                await _updateCachedSurat(targetId, body, syncStatus: 'synced');

                if (queueId != null) {
                  await _sync.removeAction(queueId);
                }

                final ctx = NavigationService.context;
                debugPrint('Surat file upload queue $queueId synced');
                if (ctx != null)
                  NotificationUtils.showSuccess(
                    ctx,
                    'Upload file surat berhasil',
                  );
              }
            } catch (_) {
              // leave queued for retry later
              debugPrint('Surat file upload $queueId failed, will retry');
            }
          }
        }
        if (queueId != null && operation != 'file_upload') {
          await _sync.removeAction(queueId);
        }
      } catch (_) {
        // increment attempts
        try {
          if (queueId != null) {
            final currentAttempts = (action['attempts'] as int?) ?? 0;
            final nextAttempts = currentAttempts + 1;
            if (nextAttempts >= 3) {
              await _sync.removeAction(queueId);
              final ctx = NavigationService.context;
              debugPrint(
                'Surat queue $queueId failed permanently after $nextAttempts attempts',
              );
              if (ctx != null)
                NotificationUtils.showError(
                  ctx,
                  'Sinkronisasi surat gagal dan dihapus dari antrean',
                );
            } else {
              await _sync.updateActionAttempts(queueId, nextAttempts);
              debugPrint(
                'Surat queue $queueId will retry later (attempt $nextAttempts)',
              );
            }
          }
        } catch (e) {
          debugPrint('Failed to update surat attempts: $e');
        }

        continue;
      }
    }
  }

  Future<void> queueFileUploadSurat({
    required int entityId,
    required String localFilePath,
    required String uploadType,
    Map<String, dynamic>? extra,
  }) async {
    await _sync.queueFileUploadSurat(
      entityId: entityId,
      localFilePath: localFilePath,
      uploadType: uploadType,
      extra: extra,
    );
  }

  /// Public wrapper to trigger pending sync (used by SyncCoordinator)
  Future<void> syncPending() async {
    final token = await local.getToken();
    if (token == null) return;
    await _processPendingQueue(token);
  }

  Future<void> _queueLocalCreate(PengajuanSurat surat) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final now = DateTime.now().toIso8601String();
    final payload = surat.toJson();
    payload['id'] = tempId;
    payload['client_temp_id'] = tempId;
    payload['sync_status'] = 'pending';
    payload['waktu_dibuat'] = payload['waktu_dibuat'] ?? now;
    payload['waktu_diubah'] = now;

    final pending = PengajuanSurat.fromJson(payload);

    await _cache.upsertSuratAllRaw(pending.toJson());
    await _cache.upsertSuratSayaRaw(pending.toJson());
    await _sync.queueCreateSurat(tempId: tempId, payload: payload);
  }

  Future<void> _queueLocalUpdate(int id, Map<String, dynamic> data) async {
    await _sync.queueUpdateSurat(entityId: id, payload: data);
  }

  Future<void> _queueLocalDelete(int id) async {
    await _sync.queueDeleteSurat(entityId: id);
  }

  Future<void> _upsertCreatedSurat(
    PengajuanSurat surat, {
    required bool cacheSaya,
    int? previousTempId,
  }) async {
    final payload = surat.copyWith(syncStatus: 'synced').toJson();

    if (previousTempId != null && previousTempId < 0) {
      await _removeCachedSurat(previousTempId);
    }

    await _cache.upsertSuratAllRaw(payload);

    if (cacheSaya) {
      await _cache.upsertSuratSayaRaw(payload);
    }
  }

  Future<void> _updateCachedSurat(
    int id,
    Map<String, dynamic> data, {
    required String syncStatus,
  }) async {
    final current = await _getCachedSuratMapById(id) ?? {'id': id};
    final merged = Map<String, dynamic>.from(current)
      ..addAll(data)
      ..['id'] = id
      ..['sync_status'] = syncStatus;

    if (merged['waktu_diubah'] == null) {
      merged['waktu_diubah'] = DateTime.now().toIso8601String();
    }

    final surat = PengajuanSurat.fromJson(merged);
    await _cache.upsertSuratAllRaw(surat.toJson());

    if (current['warga_id'] != null || data['warga_id'] != null) {
      await _cache.upsertSuratSayaRaw(surat.toJson());
    }
  }

  Future<void> _removeCachedSurat(int id) async {
    await _cache.removeSuratAll(id);
    await _cache.removeSuratSaya(id);
  }

  Future<List<PengajuanSurat>> _getCachedSuratAll() async {
    return _mapSuratList(await _cache.readSuratAllRaw());
  }

  Future<List<PengajuanSurat>> _getCachedSuratSaya() async {
    return _mapSuratList(await _cache.readSuratSayaRaw());
  }

  Future<List<PengajuanSurat>> _getCachedSuratByRt(int rtId) async {
    return _mapSuratList(await _cache.readSuratRtRaw(rtId));
  }

  Future<List<PengajuanSurat>> _getCachedSuratByRw(int rwId) async {
    return _mapSuratList(await _cache.readSuratRwRaw(rwId));
  }

  Future<PengajuanSurat?> _getCachedSuratById(int id) async {
    final raw = await _getCachedSuratMapById(id);
    if (raw == null) return null;

    return PengajuanSurat.fromJson(raw);
  }

  Future<int?> resolveSuratUploadId(int id) async {
    final raw = await _getCachedSuratMapById(id);
    final serverId = (raw?['id'] as num?)?.toInt();

    if (serverId == null || serverId <= 0) {
      return null;
    }

    return serverId;
  }

  Future<Map<String, dynamic>?> _getCachedSuratMapById(int id) async {
    final allItems = await _cache.readSuratAllRaw();
    for (final item in allItems) {
      if (_matchesSuratId(item, id)) {
        return item;
      }
    }

    final sayaItems = await _cache.readSuratSayaRaw();
    for (final item in sayaItems) {
      if (_matchesSuratId(item, id)) {
        return item;
      }
    }

    return null;
  }

  bool _matchesSuratId(Map<String, dynamic> item, int id) {
    final itemId = (item['id'] as num?)?.toInt();
    final tempId = (item['client_temp_id'] as num?)?.toInt();

    return itemId == id || tempId == id;
  }

  List<PengajuanSurat> _mapSuratList(dynamic data) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => PengajuanSurat.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  PengajuanSurat _normalizeCreatedSurat(
    dynamic data, {
    required PengajuanSurat fallback,
    int? entityIdFallback,
    int? clientTempId,
  }) {
    final raw = data is Map
        ? Map<String, dynamic>.from(data)
        : fallback.toJson();

    raw['warga_id'] ??= fallback.wargaId;
    raw['rt_id'] ??= fallback.rtId;
    raw['keperluan'] ??= fallback.keperluan;
    raw['keterangan'] ??= fallback.keterangan;
    raw['status'] ??= fallback.status.value;
    raw['doc_referensi'] ??= fallback.docRef;
    raw['catatan'] ??= fallback.catatan;
    raw['disetujui_oleh'] ??= fallback.disetujuiOleh;
    raw['waktu_disetujui'] ??= fallback.waktuDisetujui?.toIso8601String();
    raw['is_signed'] ??= fallback.isSigned;
    raw['waktu_dibuat'] ??= fallback.waktuDibuat?.toIso8601String();
    raw['waktu_diubah'] ??= fallback.waktuDiubah?.toIso8601String();
    raw['waktu_dihapus'] ??= fallback.waktuDihapus?.toIso8601String();
    raw['sync_status'] ??= 'synced';
    raw['client_temp_id'] ??= clientTempId ?? fallback.clientTempId;

    if (raw['id'] == null && entityIdFallback != null) {
      raw['id'] = entityIdFallback;
    }

    return PengajuanSurat.fromJson(raw);
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
    final meta = result['meta'];

    if (meta != null && meta['code'] != 200) {
      throw Exception(meta['message'] ?? "Unknown error");
    }

    if (result['status'] != null && result['status'] != 'success') {
      throw Exception(result['message'] ?? "Unknown error");
    }
  }
}
