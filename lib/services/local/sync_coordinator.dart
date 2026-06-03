import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/repositories/kegiatan_repository.dart';
import 'package:rukun_app_proyek4/repositories/surat_repository.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';
import 'package:rukun_app_proyek4/repositories/setoran_iuran_repository.dart';
import 'package:rukun_app_proyek4/services/local/offline_sync_status_service.dart';
import 'package:rukun_app_proyek4/services/local/navigation_service.dart';
import 'package:rukun_app_proyek4/utils/notification_utils.dart';

class SyncCoordinator {
  final Connectivity _connectivity;
  final IuranRepository _iuranRepo;
  final SuratRepository _suratRepo;
  final WargaRepository _wargaRepo;
  final SetoranIuranRtRepository _setoranRepo;
  final KKRepository _kkRepo;
  final KegiatanRepository _kegiatanRepo;

  StreamSubscription<dynamic>? _sub;

  SyncCoordinator(
    this._connectivity,
    this._iuranRepo,
    this._suratRepo,
    this._wargaRepo,
    this._setoranRepo,
    this._kkRepo,
    this._kegiatanRepo,
  );

  void start() {
    _sub = _connectivity.onConnectivityChanged.listen((dynamic result) async {
      bool online = false;
      if (result is List) {
        online = result.any((e) => e != ConnectivityResult.none);
      } else if (result is ConnectivityResult) {
        online = result != ConnectivityResult.none;
      }

      if (online) {
        await _runSyncOnce();
      }
    });
  }

  Future<void> _runSyncOnce() async {
    var anyFailed = false;

    try {
      await _iuranRepo.syncPending();
    } catch (_) {
      anyFailed = true;
    }

    try {
      await _suratRepo.syncPending();
    } catch (_) {
      anyFailed = true;
    }

    try {
      await _wargaRepo.syncPending();
    } catch (_) {
      anyFailed = true;
    }

    try {
      await _setoranRepo.syncPending();
    } catch (_) {
      anyFailed = true;
    }

    try {
      await _kkRepo.syncPending();
    } catch (_) {
      anyFailed = true;
    }

    try {
      await _kegiatanRepo.syncPending();
    } catch (_) {
      anyFailed = true;
    }

    await OfflineSyncStatusService.instance.refresh();

    // show a brief notification about sync result
    final ctx = NavigationService.context;
    if (ctx != null) {
      if (anyFailed) {
        NotificationUtils.showError(
          ctx,
          'Sinkronisasi sebagian gagal. Periksa koneksi.',
        );
      } else {
        NotificationUtils.showSuccess(
          ctx,
          'Sinkronisasi latar belakang selesai.',
        );
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
