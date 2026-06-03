import 'dart:io';

import 'package:flutter/material.dart';

import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/repositories/surat_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/surat/surat_list_viewmodel.dart';

class SuratActionViewModel extends ChangeNotifier {
  final SuratRepository suratRepo;
  final CloudinaryService cloudinaryService;
  final AuthViewModel authVm;

  SuratActionViewModel(this.suratRepo, this.cloudinaryService, this.authVm);

  bool isUploading = false;

  Future<bool> uploadDraftByRt({
    required int id,
    required File file,
    required SuratListViewModel listVm,
  }) async {
    isUploading = true;
    notifyListeners();

    try {
      final resolvedId = await suratRepo.resolveSuratUploadId(id);

      if (resolvedId == null) {
        debugPrint("SURAT BELUM TERSINKRON: $id - queueing upload");
        await suratRepo.queueFileUploadSurat(
          entityId: id,
          localFilePath: file.path,
          uploadType: 'draft',
          extra: {'disetujui_oleh': authVm.currentUser?.id},
        );

        return true;
      }

      final url = await cloudinaryService.uploadFile(
        file,
        folder: 'surat/pengajuan/$resolvedId',
      );

      if (url == null) return false;

      final body = {
        "status": "Disetujui",
        "doc_referensi": url,
        "is_signed": false,
        "disetujui_oleh": authVm.currentUser?.id,
      };

      await suratRepo.updateSurat(resolvedId, body);

      listVm.updateSuratLocal(
        id: resolvedId,
        status: SuratStatus.disetujui,
        docRef: url,
        isSigned: false,
      );

      return true;
    } catch (e) {
      debugPrint("ERROR RT UPLOAD: $e");
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadSignedByRw({
    required int id,
    required File file,
    required SuratListViewModel listVm,
  }) async {
    isUploading = true;
    notifyListeners();

    try {
      final resolvedId = await suratRepo.resolveSuratUploadId(id);

      if (resolvedId == null) {
        debugPrint("SURAT BELUM TERSINKRON: $id - queueing upload");
        await suratRepo.queueFileUploadSurat(
          entityId: id,
          localFilePath: file.path,
          uploadType: 'signed',
        );

        return true;
      }

      final url = await cloudinaryService.uploadFile(
        file,
        folder: 'surat/pengajuan/$resolvedId',
      );

      if (url == null) return false;

      final body = {
        "status": "Selesai",
        "doc_referensi": url,
        "is_signed": true,
      };

      await suratRepo.updateSurat(resolvedId, body);

      listVm.updateSuratLocal(
        id: resolvedId,
        status: SuratStatus.selesai,
        docRef: url,
        isSigned: true,
      );

      return true;
    } catch (e) {
      debugPrint("ERROR RW UPLOAD: $e");
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> tolakSurat({
    required int id,
    required String catatan,
    required SuratListViewModel listVm,
  }) async {
    isUploading = true;
    notifyListeners();

    try {
      final body = {"status": "Ditolak", "catatan": catatan};

      await suratRepo.updateSurat(id, body);

      listVm.updateSuratLocal(
        id: id,
        status: SuratStatus.ditolak,
        catatan: catatan,
      );

      return true;
    } catch (e) {
      debugPrint("ERROR REJECT SURAT: $e");
      return false;
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}
