import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/iuransaya_model.dart';
import 'package:rukun_app_proyek4/models/iuran/rw/iuran_detail_rw_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_iuran_service.dart';
import 'package:rukun_app_proyek4/services/local/local_iuran_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_iuran_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';

class IuranRepository {
  final CloudIuranService service;
  final AuthLocalService local;
  final CloudinaryService? cloudinary;

  IuranRepository(this.service, this.local, [this.cloudinary]);

  final IuranLocalCacheService cache = IuranLocalCacheService();
  final IuranLocalSyncService syncQueue = IuranLocalSyncService();

  Future<List<Iuran>> getAllIuran() async {
    final token = await local.getToken();

    if (token == null) {
      return _getCachedIuran();
    }

    try {
      await _syncPendingIuran(token);

      final result = await _safeCall(() => service.getAllIuran(token));

      _validateStatus(result);

      final List data = result['data'] ?? [];

      final rawItems = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await cache.cacheIuranRawList(rawItems);

      return rawItems.map(Iuran.fromJson).toList();
    } catch (e) {
      final cached = await _getCachedIuran();
      if (cached.isNotEmpty && _canUseCache(e)) {
        return cached;
      }

      rethrow;
    }
  }

  Future<List<IuranSaya>> getIuranSaya() async {
    final token = await _requireToken();

    final result = await _safeCall(() => service.getIuranSaya(token));

    _validateStatus(result);

    final List data = result['data'] ?? [];

    return data.map((e) => IuranSaya.fromJson(e)).toList();
  }

  Future<Iuran?> getIuranById(int id) async {
    try {
      final token = await _requireToken();
      await _syncPendingIuran(token);

      final result = await _safeCall(() => service.getIuranById(id, token));

      _validateStatus(result);

      final data = result['data'];

      if (data == null) return null;

      final raw = Map<String, dynamic>.from(data as Map);
      await cache.upsertIuranRaw(raw);

      return Iuran.fromJson(raw);
    } catch (e) {
      final cached = await _getCachedIuranById(id);
      if (cached != null && _canUseCache(e)) return cached;

      rethrow;
    }
  }

  Future<void> createIuran(Iuran iuran) async {
    try {
      final token = await _requireToken();
      await _syncPendingIuran(token);

      final result = await _safeCall(
        () => service.createIuran(iuran.toJson(), token),
      );

      _validateStatus(result);
    } catch (e) {
      if (_canUseCache(e)) {
        await _createIuranOffline(iuran);
        return;
      }

      rethrow;
    }
  }

  Future<void> updateIuran(int id, Iuran iuran) async {
    try {
      final token = await _requireToken();
      await _syncPendingIuran(token);

      final result = await _safeCall(
        () => service.updateIuran(id, iuran.toJson(), token),
      );

      _validateStatus(result);
    } catch (e) {
      if (_canUseCache(e)) {
        await _updateIuranOffline(id, iuran);
        return;
      }

      rethrow;
    }
  }

  Future<void> updateStatusTransaksi(int id, Map<String, dynamic> data) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.updateStatusTransaksi(id, data, token),
    );

    _validateStatus(result);
  }

  Future<void> deleteIuran(int id) async {
    try {
      final token = await _requireToken();
      await _syncPendingIuran(token);

      final result = await _safeCall(() => service.deleteIuran(id, token));

      _validateStatus(result);
    } catch (e) {
      if (_canUseCache(e)) {
        await _deleteIuranOffline(id);
        return;
      }

      rethrow;
    }
  }

  Future<List<Iuran>> _getCachedIuran() async {
    final raw = await cache.readIuranRaw();
    return raw.map(Iuran.fromJson).toList();
  }

  Future<Iuran?> _getCachedIuranById(int id) async {
    final raw = await cache.readIuranRaw();
    for (final item in raw) {
      if ((item['id'] as num?)?.toInt() == id) {
        return Iuran.fromJson(item);
      }
    }

    return null;
  }

  Future<void> _createIuranOffline(Iuran iuran) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final raw = _prepareOfflinePayload(iuran.toJson(), tempId);

    await cache.upsertIuranRaw(raw);
    await syncQueue.queueCreateIuran(tempId: tempId, payload: raw);
  }

  Future<void> _updateIuranOffline(int id, Iuran iuran) async {
    final raw = _prepareOfflinePayload({...iuran.toJson(), 'id': id}, id);

    await cache.upsertIuranRaw(raw);
    await syncQueue.queueUpdateIuran(entityId: id, payload: raw);
  }

  Future<void> _deleteIuranOffline(int id) async {
    await cache.removeIuran(id);
    await syncQueue.queueDeleteIuran(entityId: id);
  }

  Future<void> _syncPendingIuran(String token) async {
    final pending = await syncQueue.readPendingActions();
    if (pending.isEmpty) return;

    final tempIdMap = <int, int>{};

    for (final action in pending) {
      if (action['entity'] == 'transaksi') {
        await _syncTransaksiAction(action, token);
        continue;
      }

      if (action['entity'] != 'iuran') continue;

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
          final cleanPayload = _stripSyncFields(payload)..remove('id');

          final result = await _safeCall(
            () => service.createIuran(cleanPayload, token),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            final serverRaw = Map<String, dynamic>.from(data);
            await cache.removeIuran(entityId);
            await cache.upsertIuranRaw(serverRaw);

            final serverId = (serverRaw['id'] as num?)?.toInt();
            if (serverId != null) tempIdMap[entityId] = serverId;
          }

          await syncQueue.removeAction(queueId);
          continue;
        }

        final targetId = tempIdMap[entityId] ?? entityId;

        if (operation == 'update') {
          final cleanPayload = _stripSyncFields(payload)..remove('id');
          final result = await _safeCall(
            () => service.updateIuran(
              targetId,
              Iuran.fromJson({...cleanPayload, 'id': targetId}).toJson(),
              token,
            ),
          );
          _validateStatus(result);

          final data = result['data'];
          if (data is Map) {
            await cache.upsertIuranRaw(Map<String, dynamic>.from(data));
          } else {
            await cache.upsertIuranRaw({...cleanPayload, 'id': targetId});
          }

          await syncQueue.removeAction(queueId);
          continue;
        }

        if (operation == 'delete') {
          final result = await _safeCall(
            () => service.deleteIuran(targetId, token),
          );
          _validateStatus(result);
          await cache.removeIuran(targetId);
          await syncQueue.removeAction(queueId);
        }
      } catch (e) {
        try {
          final currentAttempts = (action['attempts'] as int?) ?? 0;
          final nextAttempts = currentAttempts + 1;
          if (nextAttempts >= 3) {
            await syncQueue.removeAction(queueId);
            debugPrint(
              'Iuran queue $queueId failed permanently after $nextAttempts attempts',
            );
          } else {
            await syncQueue.updateActionAttempts(queueId, nextAttempts);
            debugPrint(
              'Iuran queue $queueId will retry later (attempt $nextAttempts)',
            );
          }
        } catch (_) {}
        continue;
      }
    }
  }

  Future<void> _syncTransaksiAction(
    Map<String, dynamic> action,
    String token,
  ) async {
    final queueId = action['queue_id'] as String?;
    if (queueId == null) return;

    final operation = action['operation'] as String?;
    if (operation != 'transaksi_create') return;

    final payload = Map<String, dynamic>.from(
      (action['payload'] as Map?)?.cast<String, dynamic>() ?? {},
    );

    try {
      final localPath = payload['_local_file_path'] as String?;
      String? imageUrl;

      if (localPath != null && cloudinary != null) {
        final file = File(localPath);
        if (await file.exists()) {
          imageUrl = await cloudinary!.uploadFile(file, folder: 'bukti_iuran');
          if (imageUrl == null) {
            debugPrint('Transaksi sync: upload bukti failed, will retry');
            throw Exception('Upload bukti gagal');
          }
        }
      }

      final cleanPayload = _stripSyncFields(payload)..remove('id');
      if (imageUrl != null) {
        cleanPayload['img_referensi'] = imageUrl;
      }

      final result = await _safeCall(
        () => service.createTransaksi(cleanPayload, token),
      );
      _validateStatus(result);

      await syncQueue.removeAction(queueId);
      debugPrint('Transaksi sync success for $queueId');
    } catch (e) {
      try {
        final currentAttempts = (action['attempts'] as int?) ?? 0;
        final nextAttempts = currentAttempts + 1;
        if (nextAttempts >= 3) {
          await syncQueue.removeAction(queueId);
          debugPrint(
            'Transaksi queue $queueId failed permanently after $nextAttempts attempts',
          );
        } else {
          await syncQueue.updateActionAttempts(queueId, nextAttempts);
          debugPrint(
            'Transaksi queue $queueId will retry later (attempt $nextAttempts)',
          );
        }
      } catch (_) {}
    }
  }

  /// Public wrapper to trigger pending sync from outside (e.g., SyncCoordinator).
  Future<void> syncPending() async {
    final token = await _requireToken();
    await _syncPendingIuran(token);
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
    result.remove('_sync_operation');
    result.remove('_sync_status');
    result.remove('_created_offline_at');
    result.remove('_local_file_path');
    return result;
  }

  Future<List<Iuran>> getIuranByRWId(int idRw) async {
    final token = await _requireToken();

    final result = await _safeCall(() => service.getIuranByRW(idRw, token));

    _validateStatus(result);

    final List data = result['data'] ?? [];

    return data.map((e) => Iuran.fromJson(e)).toList();
  }

  Future<IuranRWDetail> getIuranRWDetail(int id) async {
    final token = await _requireToken();

    final result = await _safeCall(
      () => service.getIuranDetailWithRT(id, token),
    );

    _validateStatus(result);

    final data = result['data'];

    if (data == null) {
      throw Exception("Data tidak ditemukan");
    }

    return IuranRWDetail.fromJson(data);
  }

  Future<void> createTransaksi(
    Transaksi transaksi, {
    String? localFilePath,
  }) async {
    try {
      final token = await _requireToken();

      final result = await _safeCall(
        () => service.createTransaksi(transaksi.toJson(), token),
      );

      _validateStatus(result);
    } catch (e) {
      if (_canUseCache(e)) {
        await _createTransaksiOffline(transaksi, localFilePath: localFilePath);
        return;
      }

      rethrow;
    }
  }

  Future<void> _createTransaksiOffline(
    Transaksi transaksi, {
    String? localFilePath,
  }) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    final raw = transaksi.toJson();
    raw['id'] = tempId;
    raw['_sync_operation'] = 'transaksi_create';
    raw['_sync_status'] = 'pending';
    raw['_created_offline_at'] = DateTime.now().toIso8601String();
    if (localFilePath != null) {
      raw['_local_file_path'] = localFilePath;
    }

    await syncQueue.queueCreateTransaksi(
      tempId: tempId,
      payload: raw,
    );
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

  void _validateStatus(Map<String, dynamic> res) {
    if (res["status"] != "success") {
      throw Exception(res["message"] ?? "Unknown error");
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
}
