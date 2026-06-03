import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/user_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';
import 'package:rukun_app_proyek4/services/utils/excel_export_service.dart';

class ExportDataViewModel extends ChangeNotifier {
  final KKRepository kkRepo;
  final WargaRepository wargaRepo;
  final ExcelExportService exportService;

  ExportDataViewModel({
    required this.kkRepo,
    required this.wargaRepo,
    required this.exportService,
  });

  bool isExporting = false;
  String? errorMessage;

  /// Melakukan ekspor data untuk RW atau RT
  /// [user] digunakan untuk menentukan scope (RT ID atau RW)
  Future<bool> exportDataKependudukan(User user) async {
    isExporting = true;
    errorMessage = null;
    notifyListeners();

    try {
      List<Keluarga> listKk = [];
      List<Warga> listWarga = [];
      String scopeName = "Seluruh";

      final role = user.pengurus?.level.toUpperCase() ?? '';

      if (role == 'RW') {
        // RW mengambil seluruh data di RW tersebut
        scopeName = "RW";
        listKk = await kkRepo.getAllKK();
        listWarga = await wargaRepo.getAllWarga();
      } else if (role == 'RT') {
        // RT hanya mengambil data RT-nya
        final rtId = user.pengurus?.rtId ?? 0;
        scopeName = "RT_$rtId";
        listKk = await kkRepo.getKKByRT(rtId);
        
        // Ambil semua warga, tapi filter hanya untuk KK yang ada di RT ini
        final allWarga = await wargaRepo.getAllWarga();
        final validKkIds = listKk.map((k) => k.id).toSet();
        listWarga = allWarga.where((w) => validKkIds.contains(w.keluarga?.id)).toList();
      } else {
        throw Exception("Role tidak diizinkan mengekspor data");
      }

      await exportService.exportDataKependudukan(
        listKk: listKk,
        listWarga: listWarga,
        scopeName: scopeName,
      );

      isExporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      isExporting = false;
      errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }

  /// Melakukan ekspor data untuk satu Keluarga (KK) spesifik
  Future<bool> exportDataPerKeluarga(Keluarga kk) async {
    isExporting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (kk.id == null) throw Exception("ID Keluarga tidak valid");

      // Ambil warga khusus untuk KK ini
      final listWarga = await wargaRepo.getWargaByKeluarga(kk.id!);
      
      await exportService.exportDataKependudukan(
        listKk: [kk],
        listWarga: listWarga,
        scopeName: 'KK_${kk.noKK}',
      );

      isExporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      isExporting = false;
      errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return false;
    }
  }
}
