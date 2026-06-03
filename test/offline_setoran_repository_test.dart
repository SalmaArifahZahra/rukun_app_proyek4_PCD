import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/models/setoran_iuran_rt_model.dart';
import 'package:rukun_app_proyek4/repositories/setoran_iuran_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_setoran_iuran_service.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_sync_service.dart';

class MockCloudSetoran extends Mock implements CloudSetoranIuranRtService {}

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

  test('createSetoran falls back to offline when network error', () async {
    final mockCloud = MockCloudSetoran();
    final mockCloudinary = MockCloudinary();

    final authLocal = AuthLocalService(hiveService);
    // store a dummy token so repository attempts network call first
    await authLocal.saveToken('token-abc');

    final repo = SetoranIuranRtRepository(mockCloud, authLocal, mockCloudinary);

    // make cloud throw a connection-like exception
    when(
      () => mockCloud.createSetoran(any(), any()),
    ).thenThrow(Exception('SocketException: Failed host lookup'));

    final sample = SetoranIuranRt(
      id: null,
      iuranId: 1,
      rtId: 1,
      periodeBulan: DateTime(2026, 05, 01),
      totalPembayar: 10,
      jumlahSetoran: 100000,
    );

    // call createSetoran; should not throw, and should fallback to offline
    await repo.createSetoran(sample, localDocumentPath: null);

    final cache = SetoranIuranLocalCacheService();
    final cached = await cache.readSetoranRaw();

    expect(cached, isNotEmpty, reason: 'Cache should contain offline setoran');

    final sync = SetoranIuranLocalSyncService();
    final pending = await sync.readPendingActions();

    expect(
      pending,
      isNotEmpty,
      reason: 'Sync queue should contain create action',
    );
    expect(pending.first['entity'], 'setoran');
    expect(pending.first['operation'], 'create');
  });
}
