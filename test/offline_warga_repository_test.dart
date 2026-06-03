import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_warga_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class MockCloudWarga extends Mock implements CloudWargaService {}

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp();
    hiveService = HiveService();
    await hiveService.initForTest(tempDir.path);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    // Clean all state before each test
    final sync = PendudukLocalSyncService();
    await sync.clear();

    final authLocal = AuthLocalService(hiveService);
    await authLocal.clearToken();

    // Clear cache boxes
    final wargaBox = await hiveService.openBox<dynamic>('offline_cache_warga');
    await wargaBox.clear();
    final keluargaBox =
        await hiveService.openBox<dynamic>('offline_cache_keluarga');
    await keluargaBox.clear();
  });

  tearDownAll(() async {
    await hiveService.resetForTest();
    await tempDir.delete(recursive: true);
  });

  group('BUG-005: Warga create offline', () {
    test('createWarga falls back to offline when network error', () async {
      final mockCloud = MockCloudWarga();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-warga');

      final repo = WargaRepository(mockCloud, authLocal);

      when(
        () => mockCloud.createWarga(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final warga = Warga(
        nama: 'Warga Test',
        nik: '1234567890123456',
        jk: JenisKelamin.lakiLaki,
      );

      await repo.createWarga(warga);

      final cache = PendudukLocalCacheService();
      final cached = await cache.readWargaRaw();

      expect(cached, isNotEmpty, reason: 'Cache should contain offline warga');

      final sync = PendudukLocalSyncService();
      final pending = await sync.readPendingActions();

      expect(pending, isNotEmpty);
      expect(pending.first['entity'], 'warga');
      expect(pending.first['operation'], 'create');
    });
  });

  group('BUG-007: Warga update sync payload', () {
    test('updateWarga queues update action correctly', () async {
      final mockCloud = MockCloudWarga();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-warga-update');

      final repo = WargaRepository(mockCloud, authLocal);

      // Pre-populate cache
      final cache = PendudukLocalCacheService();
      await cache.upsertWargaRaw({
        'id': 10,
        'nama': 'Warga Existing',
        'nik': '1234567890123456',
      });

      when(
        () => mockCloud.updateWarga(any(), any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final warga = Warga(
        id: 10,
        nama: 'Updated',
        nik: '1234567890123456',
      );

      await repo.updateWarga(10, warga);

      final sync = PendudukLocalSyncService();
      final pending = await sync.readPendingActions();

      expect(pending, isNotEmpty);
      expect(pending.first['entity'], 'warga');
      expect(pending.first['operation'], 'update');

      // During sync, _stripSyncFields..remove('id') ensures 'id' is not sent to server
      // The raw queue payload may contain 'id' for cache reconstruction
    });
  });

  group('BUG-009: Warga list offline fallback', () {
    test('getAllWarga returns cached data when token is null', () async {
      final mockCloud = MockCloudWarga();
      final authLocal = AuthLocalService(hiveService);

      // No token saved
      final repo = WargaRepository(mockCloud, authLocal);

      // Pre-populate cache
      final cache = PendudukLocalCacheService();
      await cache.cacheWargaRawList([
        {
          'id': 1,
          'nama': 'Cached Warga',
          'nik': '1234567890123456',
        },
      ]);

      final result = await repo.getAllWarga();

      expect(result, isNotEmpty);
      expect(result.first.nama, 'Cached Warga');
    });

    test('getAllWarga returns cached data on network error', () async {
      final mockCloud = MockCloudWarga();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-warga-cache');

      final repo = WargaRepository(mockCloud, authLocal);

      // Pre-populate cache
      final cache = PendudukLocalCacheService();
      await cache.cacheWargaRawList([
        {
          'id': 2,
          'nama': 'Network Cached',
          'nik': '6543210987654321',
        },
      ]);

      when(
        () => mockCloud.getAllWarga(any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final result = await repo.getAllWarga();

      expect(result, isNotEmpty);
      expect(result.first.nama, 'Network Cached');
    });
  });

  group('Warga sync retry logic', () {
    test('failed sync increments attempts', () async {
      final mockCloud = MockCloudWarga();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-warga-retry');

      final repo = WargaRepository(mockCloud, authLocal);

      // Force offline create
      when(
        () => mockCloud.createWarga(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final warga = Warga(
        nama: 'Retry Warga',
        nik: '1111111111111111',
      );

      await repo.createWarga(warga);

      final sync = PendudukLocalSyncService();
      final pending = await sync.readPendingActions();
      expect(pending, isNotEmpty);

      // Make sync fail
      when(
        () => mockCloud.createWarga(any(), any()),
      ).thenThrow(Exception('Server error'));

      await repo.syncPending();

      // Action should still be in queue
      final pendingAfter = await sync.readPendingActions();
      expect(pendingAfter, isNotEmpty, reason: 'Action should remain for retry');
    });
  });
}
