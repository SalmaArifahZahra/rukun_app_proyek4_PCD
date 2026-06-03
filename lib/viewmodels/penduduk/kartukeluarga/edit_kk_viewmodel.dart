import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';

class EditKKViewModel extends ChangeNotifier {
  final KKRepository kkRepository;

  final int idKK;

  EditKKViewModel({
    required this.kkRepository,
    required this.idKK,
  }) {
    getDetailKK();
  }

  bool isLoading = false;
  bool isSaving = false;

  String? errorMessage;

  Keluarga? kk;

  File? fotoKK;

  /// url image lama
  String? fotoKKUrl;

  String noKK = '';
  String alamat = '';
  String kodePos = '';
  String desa = '';
  String kecamatan = '';

  Future<void> getDetailKK() async {
    try {
      isLoading = true;
      errorMessage = null;

      notifyListeners();

      final result = await kkRepository.getKKById(idKK);

      if (result == null) {
        throw Exception("Data KK tidak ditemukan");
      }

      kk = result;

      noKK = result.noKK;
      alamat = result.alamat ?? '';
      kodePos = result.kodePos ?? '';
      desa = result.desa ?? '';
      kecamatan = result.kecamatan ?? '';

      fotoKKUrl = result.imgRef;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> pickFotoKK() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      fotoKK = File(picked.path);
      notifyListeners();
    }
  }

  void setFotoKK(File file) {
    fotoKK = file;
    notifyListeners();
  }

  Future<void> updateKK() async {
    try {
      isSaving = true;
      errorMessage = null;

      notifyListeners();

      if (kk == null) {
        throw Exception("Data KK belum dimuat");
      }

      final data = {
        "no_kk": noKK,
        "alamat": alamat,
        "kode_pos": kodePos,
        "desa": desa,
        "kecamatan": kecamatan,
        "img_referensi": fotoKKUrl,
      };

      // If there's a new photo, include local path for sync upload
      if (fotoKK != null) {
        data['local_foto_path'] = fotoKK!.path;
      }

      await kkRepository.updateKK(idKK, data);
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    }

    isSaving = false;
    notifyListeners();
  }
}
