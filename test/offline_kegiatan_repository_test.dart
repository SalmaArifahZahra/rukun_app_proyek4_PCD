import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/repositories/kegiatan_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_kegiatan_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/local/local_kegiatan_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_kegiatan_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class MockCloudKegiatan extends Mock implements CloudKegiatanService {}

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
    final authLocal = AuthLocalService(hiveService);
    await authLocal.clearToken();

    final sync = KegiatanLocalSyncService();
    final box = await hiveService.openBox<dynamic>('offline_sync_kegiatan');
    await box.clear();

    final cacheBox =
        await hiveService.openBox<dynamic>('offline_cache_kegiatan');
    await cacheBox.clear();
  });

  tearDownAll(() async {
    await hiveService.resetForTest();
    await tempDir.delete(recursive: true);
  });

  group('BUG-017/018/019: Kegiatan offline CRUD', () {
    test('createKegiatan falls back to offline when network error', () async {
      final mockCloud = MockCloudKegiatan();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-kegiatan');

      final repo = KegiatanRepository(mockCloud, authLocal);

      when(
        () => mockCloud.createKegiatan(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final kegiatan = Kegiatan(
        nama: 'Kegiatan Test',
        deskripsi: 'Deskripsi test',
        tanggalMulai: DateTime(2026, 6, 1),
        tanggalSelesai: DateTime(2026, 6, 2),
        level: KegiatanLevel.rt,
        status: KegiatanStatus.dibuat,
        rtId: 1,
        rwId: 1,
      );

      await repo.createKegiatan(kegiatan);

      final cache = KegiatanLocalCacheService();
      final cached = await cache.readKegiatanRaw();

      expect(cached, isNotEmpty, reason: 'Cache should contain offline kegiatan');

      final sync = KegiatanLocalSyncService();
      final pending = await sync.readPendingActions();

      expect(pending, isNotEmpty);
      expect(pending.first['entity'], 'kegiatan');
      expect(pending.first['operation'], 'create');
    });

    test('updateKegiatan queues offline when network error', () async {
      final mockCloud = MockCloudKegiatan();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-kegiatan');

      final repo = KegiatanRepository(mockCloud, authLocal);

      // Pre-populate cache with an existing kegiatan
      final cache = KegiatanLocalCacheService();
      await cache.upsertKegiatanRaw({
        'id': 10,
        'nama': 'Kegiatan Existing',
        'deskripsi': 'Deskripsi',
        'tanggal_mulai': DateTime(2026, 6, 1).toIso8601String(),
        'tanggal_selesai': DateTime(2026, 6, 2).toIso8601String(),
        'level': 'RT',
        'status': 'Dibuat',
        'rt_id': 1,
        'rw_id': 1,
      });

      when(
        () => mockCloud.updateKegiatan(any(), any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      await repo.updateKegiatan(10, {'nama': 'Updated'});

      final sync = KegiatanLocalSyncService();
      final pending = await sync.readPendingActions();

      expect(pending, isNotEmpty);
      expect(pending.first['entity'], 'kegiatan');
      expect(pending.first['operation'], 'update');
    });

    test('kegiatan sync retry logic increments attempts on failure', () async {
      final mockCloud = MockCloudKegiatan();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-kegiatan-sync');

      final repo = KegiatanRepository(mockCloud, authLocal);

      // Force offline create
      when(
        () => mockCloud.createKegiatan(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final kegiatan = Kegiatan(
        nama: 'Kegiatan Sync Test',
        deskripsi: 'Test sync',
        tanggalMulai: DateTime(2026, 6, 1),
        tanggalSelesai: DateTime(2026, 6, 2),
        level: KegiatanLevel.rt,
        status: KegiatanStatus.dibuat,
        rtId: 1,
        rwId: 1,
      );

      await repo.createKegiatan(kegiatan);

      final sync = KegiatanLocalSyncService();
      final pendingBefore = await sync.readPendingActions();
      expect(pendingBefore, isNotEmpty);

      // Make sync fail
      when(
        () => mockCloud.createKegiatan(any(), any()),
      ).thenThrow(Exception('Server error'));

      await repo.syncPending();

      // Action should still be in queue (attempts < 3)
      final pendingAfter = await sync.readPendingActions();
      expect(pendingAfter, isNotEmpty, reason: 'Action should remain for retry');
    });

    test('kegiatan sync removes action after 3 failures', () async {
      final mockCloud = MockCloudKegiatan();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-kegiatan-permanent');

      final repo = KegiatanRepository(mockCloud, authLocal);

      // Force offline create
      when(
        () => mockCloud.createKegiatan(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final kegiatan = Kegiatan(
        nama: 'Kegiatan Permanent Fail',
        deskripsi: 'Test permanent fail',
        tanggalMulai: DateTime(2026, 6, 1),
        tanggalSelesai: DateTime(2026, 6, 2),
        level: KegiatanLevel.rt,
        status: KegiatanStatus.dibuat,
        rtId: 1,
        rwId: 1,
      );

      await repo.createKegiatan(kegiatan);

      final sync = KegiatanLocalSyncService();

      // Simulate 3 failed sync attempts
      when(
        () => mockCloud.createKegiatan(any(), any()),
      ).thenThrow(Exception('Server error'));

      await repo.syncPending(); // attempt 1
      await repo.syncPending(); // attempt 2
      await repo.syncPending(); // attempt 3 — should remove

      final pendingAfter = await sync.readPendingActions();
      expect(
        pendingAfter.isEmpty,
        true,
        reason: 'Action should be removed after 3 failures',
      );
    });

    test('getAllKegiatan returns cached data when token is null', () async {
      final mockCloud = MockCloudKegiatan();
      final authLocal = AuthLocalService(hiveService);

      // No token saved
      final repo = KegiatanRepository(mockCloud, authLocal);

      // Pre-populate cache
      final cache = KegiatanLocalCacheService();
      await cache.cacheKegiatanRawList([
        {
          'id': 1,
          'nama': 'Cached Kegiatan',
          'deskripsi': 'Deskripsi',
          'tanggal_mulai': DateTime(2026, 6, 1).toIso8601String(),
          'level': 'RT',
          'status': 'Dibuat',
          'rt_id': 1,
          'rw_id': 1,
        },
      ]);

      final result = await repo.getAllKegiatan();

      expect(result, isNotEmpty);
      expect(result.first.nama, 'Cached Kegiatan');
    });
  });
}
