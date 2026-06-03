import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rukun_app_proyek4/repositories/dashboard_repository.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_dashboard_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/models/dashboard_model.dart';

class MockCloudDashboardService extends Mock
    implements CloudDashboardService {}

class MockAuthLocalService extends Mock implements AuthLocalService {}

void main() {
  late DashboardRepository repository;
  late MockCloudDashboardService service;
  late MockAuthLocalService local;

  setUp(() {
    service = MockCloudDashboardService();
    local = MockAuthLocalService();

    repository = DashboardRepository(service, local);
  });

  group('DashboardRepository Test', () {
    test('getDashboardRW success', () async {
      // ARRANGE
      when(() => local.getToken()).thenAnswer((_) async => 'token-123');

      when(() => service.getDashboardRW(any())).thenAnswer(
        (_) async => {
          "status": "success",
          "data": {
            "total_kegiatan": 10,
            "total_warga": 50,
          }
        },
      );

      // ACT
      final result = await repository.getDashboardRW();

      // ASSERT
      expect(result, isA<DashboardModel>());

      verify(() => local.getToken()).called(1);
      verify(() => service.getDashboardRW('token-123')).called(1);
    });

    test('getDashboardRT success', () async {
      when(() => local.getToken()).thenAnswer((_) async => 'token-abc');

      when(() => service.getDashboardRT(any())).thenAnswer(
        (_) async => {
          "status": "success",
          "data": {
            "total_kegiatan": 5,
            "total_warga": 20,
          }
        },
      );

      final result = await repository.getDashboardRT();

      expect(result, isA<DashboardModel>());

      verify(() => service.getDashboardRT('token-abc')).called(1);
    });

    test('throw error when token null', () async {
      when(() => local.getToken()).thenAnswer((_) async => null);

      expect(
        () => repository.getDashboardRW(),
        throwsException,
      );
    });

    test('throw error when status not success', () async {
      when(() => local.getToken()).thenAnswer((_) async => 'token');

      when(() => service.getDashboardRW(any())).thenAnswer(
        (_) async => {
          "status": "error",
          "message": "Forbidden",
        },
      );

      expect(
        () => repository.getDashboardRW(),
        throwsException,
      );
    });

    test('dio exception handled properly', () async {
      when(() => local.getToken()).thenAnswer((_) async => 'token');

      when(() => service.getDashboardRW(any()))
          .thenThrow(Exception("network error"));

      expect(
        () => repository.getDashboardRW(),
        throwsException,
      );
    });
  });
}