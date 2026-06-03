import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/models/setoran_iuran_rt_model.dart';
import 'package:rukun_app_proyek4/repositories/setoran_iuran_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_setoran_iuran_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class MockCloudSetoran extends Mock implements CloudSetoranIuranRtService {}

class MockCloudinary extends Mock implements CloudinaryService {}

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp();
    hiveService = HiveService();
    await hiveService.initForTest(tempDir.path);
    registerFallbackValue(File('fallback.pdf'));
  });

  tearDown(() async {
    final authLocal = AuthLocalService(hiveService);
    await authLocal.clearToken();
  });

  tearDownAll(() async {
    await hiveService.resetForTest();
    await tempDir.delete(recursive: true);
  });

  group('BUG-010: Setoran upload failure retry', () {
    test(
      'setoran with local file path retries on upload failure',
      () async {
        final mockCloud = MockCloudSetoran();
        final mockCloudinary = MockCloudinary();
        final authLocal = AuthLocalService(hiveService);

        await authLocal.saveToken('token-setoran-upload');

        final repo = SetoranIuranRtRepository(
          mockCloud,
          authLocal,
          mockCloudinary,
        );

        // Force offline create
        when(
          () => mockCloud.createSetoran(any(), any()),
        ).thenThrow(Exception('SocketException: Failed host lookup'));

        final localFile = File('${tempDir.path}/bukti-upload-test.pdf');
        await localFile.writeAsString('dummy pdf content');

        final setoran = SetoranIuranRt(
          id: null,
          iuranId: 1,
          rtId: 1,
          periodeBulan: DateTime(2026, 05, 01),
          totalPembayar: 10,
          jumlahSetoran: 100000,
        );

        await repo.createSetoran(setoran, localDocumentPath: localFile.path);

        final cache = SetoranIuranLocalCacheService();
        final cached = await cache.readSetoranRaw();
        expect(cached, isNotEmpty);

        final sync = SetoranIuranLocalSyncService();
        final pending = await sync.readPendingActions();
        expect(pending, isNotEmpty);
        expect(pending.first['entity'], 'setoran');
        expect(pending.first['operation'], 'create');

        // Verify local_document_path is in payload
        final payload =
            pending.first['payload'] as Map<String, dynamic>;
        expect(
          payload['local_document_path'],
          localFile.path,
          reason: 'Local file path should be preserved for later upload',
        );

        // Make upload fail
        when(
          () => mockCloudinary.uploadFile(any(), folder: any(named: 'folder')),
        ).thenAnswer((_) async => null);

        // Make create fail (will trigger retry)
        when(
          () => mockCloud.createSetoran(any(), any()),
        ).thenThrow(Exception('Server error'));

        await repo.syncPending();

        // Action should still be in queue (upload failed → retry)
        final pendingAfter = await sync.readPendingActions();
        expect(
          pendingAfter.where((e) => e['entity'] == 'setoran').isNotEmpty,
          true,
          reason: 'Setoran should remain in queue after upload failure',
        );
      },
    );
  });

  group('BUG-009: Setoran list offline fallback', () {
    test('getAllSetoran returns cached data when token is null', () async {
      final mockCloud = MockCloudSetoran();
      final mockCloudinary = MockCloudinary();
      final authLocal = AuthLocalService(hiveService);

      // No token saved
      final repo = SetoranIuranRtRepository(
        mockCloud,
        authLocal,
        mockCloudinary,
      );

      // Pre-populate cache with complete data
      final cache = SetoranIuranLocalCacheService();
      await cache.upsertSetoranRaw({
        'id': 1,
        'iuran_id': 1,
        'rt_id': 1,
        'jumlah_setoran': 100000,
        'periode_bulan': '2026-05-01',
        'total_pembayar': 10,
        'status': 'Diajukan',
      });

      final result = await repo.getAllSetoran();

      expect(result, isNotEmpty);
    });
  });
}
