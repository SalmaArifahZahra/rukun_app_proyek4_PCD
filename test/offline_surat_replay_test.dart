import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/repositories/surat_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_surat_service.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/services/local/local_surat_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_surat_sync_service.dart';

class MockCloudSurat extends Mock implements CloudSuratService {}

class MockCloudinary extends Mock implements CloudinaryService {}

void main() {
  late Directory tempDir;
  late HiveService hiveService;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp();
    hiveService = HiveService();
    await hiveService.initForTest(tempDir.path);
  });

  tearDownAll(() async {
    await hiveService.resetForTest();
    await tempDir.delete(recursive: true);
  });

  test(
    'replay pending create replaces temp id with server id and clears queue',
    () async {
      final mockCloud = MockCloudSurat();
      final mockCloudinary = MockCloudinary();

      final authLocal = AuthLocalService(hiveService);
      await authLocal.saveToken('token-replay');

      final repo = SuratRepository(mockCloud, authLocal, mockCloudinary);

      // First, make createSurat throw to force offline queue
      when(
        () => mockCloud.createSurat(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final surat = PengajuanSurat(
        id: null,
        wargaId: 10,
        rtId: 2,
        keperluan: 'Surat Uji Replay',
      );

      await repo.createSurat(surat);

      final cache = SuratLocalCacheService();
      final allBefore = await cache.readSuratAllRaw();

      // ensure there's a pending local item with client_temp_id negative
      final hasTemp = allBefore.any((item) {
        final temp = (item['client_temp_id'] as num?)?.toInt();
        return temp != null && temp < 0;
      });

      expect(
        hasTemp,
        true,
        reason: 'Should have a temp offline surat in cache',
      );

      final sync = SuratLocalSyncService();
      final pendingBefore = await sync.readPendingActions();
      expect(pendingBefore.isNotEmpty, true);

      // Now simulate server success for create during replay
      when(() => mockCloud.createSurat(any(), any())).thenAnswer((_) async {
        return {
          'status': 'success',
          'data': {
            'id': 5001,
            'warga_id': 10,
            'rt_id': 2,
            'keperluan': 'Surat Uji Replay',
          },
        };
      });

      // run syncPending which should process the queued create
      final pendingBeforeSync = await sync.readPendingActions();
      print('pendingBeforeSync: $pendingBeforeSync');

      await repo.syncPending();

      final pendingAfterSyncImmediate = await sync.readPendingActions();
      print('pendingAfterSyncImmediate: $pendingAfterSyncImmediate');

      final allAfter = await cache.readSuratAllRaw();
      print('cache after sync: $allAfter');

      // No item should have id negative (reconciled to server id)
      final hasNegativeId = allAfter.any((item) {
        final id = (item['id'] as num?)?.toInt();
        return id != null && id < 0;
      });

      expect(hasNegativeId, false, reason: 'No record should keep negative id');

      // server id 5001 should exist in cache
      final hasServer = allAfter.any(
        (item) => (item['id'] as num?)?.toInt() == 5001,
      );
      expect(hasServer, true, reason: 'Server-created id should be in cache');
    },
  );
}
