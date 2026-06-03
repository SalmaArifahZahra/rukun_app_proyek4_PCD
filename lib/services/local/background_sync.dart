import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:rukun_app_proyek4/services/utils/hive_service.dart';
import 'package:rukun_app_proyek4/services/auth/auth_local_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_iuran_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_kegiatan_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_kk_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_surat_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_warga_service.dart';
import 'package:rukun_app_proyek4/services/cloud/cloud_setoran_iuran_service.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/repositories/kegiatan_repository.dart';
import 'package:rukun_app_proyek4/repositories/surat_repository.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';
import 'package:rukun_app_proyek4/repositories/setoran_iuran_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';

/// Top-level callback for WorkManager. This runs in a separate isolate.
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      final hive = HiveService();
      await hive.init();

      final authLocal = AuthLocalService(hive);

      final cloudIuran = CloudIuranService();
      final cloudSurat = CloudSuratService();
      final cloudWarga = CloudWargaService();
      final cloudSetoran = CloudSetoranIuranRtService();
      final cloudKK = CloudKKService();

      final cloudinary = CloudinaryService();

      final iuranRepo = IuranRepository(cloudIuran, authLocal, cloudinary);
      final suratRepo = SuratRepository(cloudSurat, authLocal, cloudinary);
      final wargaRepo = WargaRepository(cloudWarga, authLocal);
      final setoranRepo = SetoranIuranRtRepository(
        cloudSetoran,
        authLocal,
        cloudinary,
      );
      final kkRepo = KKRepository(cloudKK, authLocal, cloudinary);
      final cloudKegiatan = CloudKegiatanService();
      final kegiatanRepo = KegiatanRepository(cloudKegiatan, authLocal);

      // Run sync for each repository. Ignore individual failures.
      try {
        await iuranRepo.syncPending();
      } catch (_) {}
      try {
        await suratRepo.syncPending();
      } catch (_) {}
      try {
        await wargaRepo.syncPending();
      } catch (_) {}
      try {
        await setoranRepo.syncPending();
      } catch (_) {}
      try {
        await kkRepo.syncPending();
      } catch (_) {}
      try {
        await kegiatanRepo.syncPending();
      } catch (_) {}

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}
