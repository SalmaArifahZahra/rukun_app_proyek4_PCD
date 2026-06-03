import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';

class RTUploadSetoranRWViewModel extends ChangeNotifier {
  final IuranRepository repository;
  final CloudinaryService cloudinaryService;

  RTUploadSetoranRWViewModel({
    required this.repository,
    required this.cloudinaryService,
  });

  bool isLoading = false;

  String? errorMessage;

  File? buktiFile;

  final picker = ImagePicker();

  Future<void> pickBukti() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    buktiFile = File(picked.path);

    notifyListeners();
  }

  Future<bool> submit({required int iuranId, required int nominal}) async {
    try {
      isLoading = true;

      errorMessage = null;

      notifyListeners();

      if (buktiFile == null) {
        throw Exception("Bukti transfer wajib diupload");
      }

      final imageUrl = await cloudinaryService.uploadFile(
        buktiFile!,
        folder: "setoran_rt_rw",
      );

      if (imageUrl == null) {
        throw Exception("Gagal upload bukti");
      }

      final data = Transaksi(
        iuranId: iuranId,
        jumlah: nominal,
        status: StatusPembayaran.diproses,
        imgRef: imageUrl,
        catatan: "RT_SETORAN_RW",
      );

      await repository.createTransaksi(data);

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");

      return false;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }
}
