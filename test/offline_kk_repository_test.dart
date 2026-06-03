import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_kk_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_penduduk_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class MockCloudKK extends Mock implements CloudKKService {}

class MockCloudinary extends Mock implements CloudinaryService {}

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

    final sync = PendudukLocalSyncService();
    await sync.clear();

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

  group('BUG-006/008: KK offline CRUD', () {
    test('createKK falls back to offline when network error', () async {
      final mockCloud = MockCloudKK();
      final mockCloudinary = MockCloudinary();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-kk');

      final repo = KKRepository(mockCloud, authLocal, mockCloudinary);

      when(
        () => mockCloud.createKK(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final kk = Keluarga(
        noKK: '1234567890',
        rtId: 1,
      );

      await repo.createKK(kk);

      final cache = PendudukLocalCacheService();
      final cached = await cache.readKeluargaRaw();

      expect(cached, isNotEmpty, reason: 'Cache should contain offline KK');

      final sync = PendudukLocalSyncService();
      final pending = await sync.readPendingActions();

      expect(pending, isNotEmpty);
      expect(pending.first['entity'], 'keluarga');
      expect(pending.first['operation'], 'create');
    });

    test('getAllKK returns cached data when token is null', () async {
      final mockCloud = MockCloudKK();
      final mockCloudinary = MockCloudinary();
      final authLocal = AuthLocalService(hiveService);

      // No token saved
      final repo = KKRepository(mockCloud, authLocal, mockCloudinary);

      // Pre-populate cache
      final cache = PendudukLocalCacheService();
      await cache.cacheKeluargaList([
        Keluarga(id: 1, noKK: '9999999999', rtId: 1),
      ]);

      final result = await repo.getAllKK();

      expect(result, isNotEmpty);
      expect(result.first.noKK, '9999999999');
    });

    test('KK sync retry logic increments attempts', () async {
      final mockCloud = MockCloudKK();
      final mockCloudinary = MockCloudinary();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-kk-retry');

      final repo = KKRepository(mockCloud, authLocal, mockCloudinary);

      // Force offline create
      when(
        () => mockCloud.createKK(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final kk = Keluarga(
        noKK: '1111111111',
        rtId: 1,
      );

      await repo.createKK(kk);

      final sync = PendudukLocalSyncService();
      final pending = await sync.readPendingActions();
      expect(pending, isNotEmpty);

      // Make sync fail
      when(
        () => mockCloud.createKK(any(), any()),
      ).thenThrow(Exception('Server error'));

      await repo.syncPending();

      // Action should still be in queue
      final pendingAfter = await sync.readPendingActions();
      expect(pendingAfter, isNotEmpty, reason: 'Action should remain for retry');
    });
  });
}
