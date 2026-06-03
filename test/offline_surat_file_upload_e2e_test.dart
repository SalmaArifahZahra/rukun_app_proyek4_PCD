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
    // register fallback File for mocktail
    registerFallbackValue(File(''));
  });

  tearDownAll(() async {
    await hiveService.resetForTest();
    await tempDir.delete(recursive: true);
  });

  test(
    'end-to-end: create offline + file_upload syncs upload and updates cache',
    () async {
      final mockCloud = MockCloudSurat();
      final mockCloudinary = MockCloudinary();

      final authLocal = AuthLocalService(hiveService);
      await authLocal.saveToken('token-upload-e2e');

      final repo = SuratRepository(mockCloud, authLocal, mockCloudinary);

      // Make createSurat fail initially to force offline queue
      when(
        () => mockCloud.createSurat(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final surat = PengajuanSurat(
        id: null,
        wargaId: 20,
        rtId: 3,
        keperluan: 'Surat Upload E2E',
      );

      // Create offline (queued)
      await repo.createSurat(surat);

      // Find temp id from cache
      final cache = SuratLocalCacheService();
      final all = await cache.readSuratAllRaw();
      final tempItem = all.firstWhere(
        (it) => (it['client_temp_id'] as num?) != null,
      );
      final tempId = (tempItem['client_temp_id'] as num).toInt();

      // Queue file upload referencing temp id
      await repo.queueFileUploadSurat(
        entityId: tempId,
        localFilePath: '/tmp/fake_upload.pdf',
        uploadType: 'draft',
        extra: {'disetujui_oleh': 42},
      );

      // Now set up mocks for successful replay: first createSurat returns server id
      when(() => mockCloud.createSurat(any(), any())).thenAnswer((_) async {
        return {
          'status': 'success',
          'data': {
            'id': 7001,
            'warga_id': 20,
            'rt_id': 3,
            'keperluan': 'Surat Upload E2E',
          },
        };
      });

      // cloudinary upload returns a URL
      when(
        () => mockCloudinary.uploadFile(any(), folder: any(named: 'folder')),
      ).thenAnswer((_) async => 'https://cdn.example.com/surat7001.pdf');

      // updateSurat should succeed
      when(() => mockCloud.updateSurat(7001, any(), any())).thenAnswer(
        (_) async => {
          'status': 'success',
          'data': {'id': 7001},
        },
      );

      // run syncPending to process create + file_upload
      await repo.syncPending();

      final allAfter = await cache.readSuratAllRaw();
      print('cache after final sync: $allAfter');

      // expect server id present and doc_referensi set
      final server = allAfter.firstWhere(
        (it) => (it['id'] as num?)?.toInt() == 7001,
      );
      expect(server, isNotNull);
      expect(server['doc_referensi'], 'https://cdn.example.com/surat7001.pdf');

      // pending queue may still contain retry-able items (attempts) but primary goal
      // is that upload was applied and cache updated.
    },
  );
}
