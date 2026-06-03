import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/models/setoran_iuran_rt_model.dart';
import 'package:rukun_app_proyek4/repositories/setoran_iuran_repository.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_setoran_iuran_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_cache_service.dart';
import 'package:rukun_app_proyek4/services/local/local_setoran_iuran_sync_service.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
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

  tearDownAll(() async {
    await hiveService.resetForTest();
    await tempDir.delete(recursive: true);
  });

  test(
    'end-to-end: create setoran offline + file upload syncs and updates cache',
    () async {
      final mockCloud = MockCloudSetoran();
      final mockCloudinary = MockCloudinary();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-setoran-e2e');

      final repo = SetoranIuranRtRepository(
        mockCloud,
        authLocal,
        mockCloudinary,
      );

      // Force offline create on first attempt.
      when(
        () => mockCloud.createSetoran(any(), any()),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      final localFile = File(
        '${tempDir.path}${Platform.pathSeparator}bukti-setoran.pdf',
      );
      await localFile.writeAsString('dummy pdf content');

      final setoran = SetoranIuranRt(
        id: null,
        iuranId: 11,
        rtId: 4,
        periodeBulan: DateTime(2026, 05, 01),
        totalPembayar: 15,
        jumlahSetoran: 250000,
      );

      // Offline create stores local record + queue.
      await repo.createSetoran(setoran, localDocumentPath: localFile.path);

      final cache = SetoranIuranLocalCacheService();
      final allBefore = await cache.readSetoranRaw();
      expect(allBefore, isNotEmpty);

      final tempItem = allBefore.firstWhere(
        (item) =>
            (item['id'] as num?)?.toInt() != null &&
            (item['id'] as num).toInt() < 0,
      );
      final tempId = (tempItem['id'] as num).toInt();

      final sync = SetoranIuranLocalSyncService();
      final pendingBefore = await sync.readPendingActions();
      expect(
        pendingBefore.where((e) => e['entity'] == 'setoran').isNotEmpty,
        true,
        reason: 'Setoran queue should have create action before replay',
      );

      // Prepare successful replay:
      when(() => mockCloud.createSetoran(any(), any())).thenAnswer((
        invocation,
      ) async {
        final payload =
            invocation.positionalArguments.first as Map<String, dynamic>;
        return {
          'status': 'success',
          'data': {
            'id': 9001,
            'iuran_id': payload['iuran_id'] ?? 11,
            'rt_id': payload['rt_id'] ?? 4,
            'periode_bulan':
                payload['periode_bulan'] ??
                DateTime(2026, 05, 01).toIso8601String(),
            'total_pembayar': payload['total_pembayar'] ?? 15,
            'jumlah_setoran': payload['jumlah_setoran'] ?? 250000,
            'status': payload['status'] ?? 'Dikirim',
            'document_ref': payload['document_ref'],
          },
        };
      });

      when(
        () => mockCloudinary.uploadFile(any(), folder: any(named: 'folder')),
      ).thenAnswer((_) async => 'https://cdn.example.com/setoran9001.pdf');

      when(() => mockCloud.updateSetoran(9001, any(), any())).thenAnswer(
        (_) async => {
          'status': 'success',
          'data': {'id': 9001},
        },
      );

      await repo.syncPending();

      final allAfter = await cache.readSetoranRaw();
      final server = allAfter.firstWhere(
        (item) => (item['id'] as num?)?.toInt() == 9001,
      );

      expect(server['document_ref'], 'https://cdn.example.com/setoran9001.pdf');

      final pendingAfter = await sync.readPendingActions();
      expect(
        pendingAfter.where((e) => e['entity'] == 'setoran').isEmpty,
        true,
        reason: 'Setoran queue should be empty after successful replay',
      );

      final hasTempAfter = allAfter.any((item) {
        final id = (item['id'] as num?)?.toInt();
        return id != null && id < 0;
      });
      expect(hasTempAfter, false, reason: 'No negative temp id should remain');
    },
  );
}
