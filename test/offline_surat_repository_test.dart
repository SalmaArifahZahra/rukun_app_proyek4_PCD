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

  test('createSurat falls back to offline when network error', () async {
    final mockCloud = MockCloudSurat();
    final mockCloudinary = MockCloudinary();

    final authLocal = AuthLocalService(hiveService);
    await authLocal.saveToken('token-xyz');

    final repo = SuratRepository(mockCloud, authLocal, mockCloudinary);

    when(
      () => mockCloud.createSurat(any(), any()),
    ).thenThrow(Exception('SocketException: Failed host lookup'));

    final surat = PengajuanSurat(
      id: null,
      wargaId: 1,
      rtId: 1,
      keperluan: 'Surat Keterangan',
    );

    await repo.createSurat(surat);

    final cache = SuratLocalCacheService();
    final all = await cache.readSuratAllRaw();

    expect(all, isNotEmpty, reason: 'Cache should contain offline surat');

    final sync = SuratLocalSyncService();
    final pending = await sync.readPendingActions();

    expect(
      pending,
      isNotEmpty,
      reason: 'Sync queue should contain create action',
    );
    expect(pending.first['entity'], 'surat');
    expect(pending.first['operation'], 'create');
  });

  test('queueFileUploadSurat enqueues file_upload action', () async {
    final mockCloud = MockCloudSurat();
    final mockCloudinary = MockCloudinary();

    final authLocal = AuthLocalService(hiveService);
    await authLocal.saveToken('token-xyz');

    final repo = SuratRepository(mockCloud, authLocal, mockCloudinary);

    // queue a file upload for a temp entity id (negative)
    final tempId = -12345;
    await repo.queueFileUploadSurat(
      entityId: tempId,
      localFilePath: '/tmp/fake.pdf',
      uploadType: 'draft',
      extra: {'disetujui_oleh': 1},
    );

    final sync = SuratLocalSyncService();
    final pending = await sync.readPendingActions();

    final found = pending.firstWhere(
      (e) => e['operation'] == 'file_upload' && e['entity'] == 'surat',
      orElse: () => <String, dynamic>{},
    );

    expect(
      found.isNotEmpty,
      true,
      reason: 'file_upload action should be queued',
    );
    expect(found['payload']['local_file_path'], '/tmp/fake.pdf');
  });
}
