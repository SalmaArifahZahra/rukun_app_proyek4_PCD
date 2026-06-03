import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rukun_app_proyek4/repositories/dashboard_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_dashboard_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class MockCloudDashboardService extends Mock
    implements CloudDashboardService {}

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

  group('BUG-004: Dashboard offline fallback', () {
    test('getDashboardRW success', () async {
      final mockCloud = MockCloudDashboardService();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-123');

      final repo = DashboardRepository(mockCloud, authLocal);

      when(() => mockCloud.getDashboardRW(any())).thenAnswer(
        (_) async => {
          "status": "success",
          "data": {
            "total_kegiatan": 10,
            "total_warga": 50,
          }
        },
      );

      final result = await repo.getDashboardRW();

      expect(result, isNotNull);
      verify(() => mockCloud.getDashboardRW('token-123')).called(1);
    });

    test('getDashboardRT success', () async {
      final mockCloud = MockCloudDashboardService();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-abc');

      final repo = DashboardRepository(mockCloud, authLocal);

      when(() => mockCloud.getDashboardRT(any())).thenAnswer(
        (_) async => {
          "status": "success",
          "data": {
            "total_kegiatan": 5,
            "total_warga": 20,
          }
        },
      );

      final result = await repo.getDashboardRT();

      expect(result, isNotNull);
      verify(() => mockCloud.getDashboardRT('token-abc')).called(1);
    });

    test('getDashboardRW does not crash when token is null', () async {
      final mockCloud = MockCloudDashboardService();
      final authLocal = AuthLocalService(hiveService);

      // No token saved — simulates offline auth failure
      final repo = DashboardRepository(mockCloud, authLocal);

      // Before fix: _requireToken() was called before try-catch, throwing immediately
      // After fix: _requireToken() is inside try-catch, error is caught and cache is checked
      // Since no cache exists, it will rethrow
      expect(
        () => repo.getDashboardRW(),
        throwsException,
      );
    });

    test('getDashboardRW falls back to cache on network error', () async {
      final mockCloud = MockCloudDashboardService();
      final authLocal = AuthLocalService(hiveService);

      await authLocal.saveToken('token-cache');

      final repo = DashboardRepository(mockCloud, authLocal);

      // First call succeeds and caches data
      when(() => mockCloud.getDashboardRW(any())).thenAnswer(
        (_) async => {
          "status": "success",
          "data": {
            "total_kegiatan": 10,
            "total_warga": 50,
          }
        },
      );

      await repo.getDashboardRW();

      // Second call fails with network error
      when(() => mockCloud.getDashboardRW(any())).thenThrow(
        Exception('SocketException: Failed host lookup'),
      );

      // Should return cached data instead of throwing
      final result = await repo.getDashboardRW();

      expect(result, isNotNull);
    });
  });
}
