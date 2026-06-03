import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/iuransaya_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/iuran/iuranwarga_viewmodel.dart';

class UploadIuranViewModel extends ChangeNotifier {
  final IuranSaya item;
  final int keluargaId;
  final CloudinaryService cloudinaryService;
  final IuranRepository iuranRepository;
  IuranItem selectedItem;

  UploadIuranViewModel({
    required this.item,
    required this.keluargaId,
    required this.cloudinaryService,
    required this.iuranRepository,
    required this.selectedItem,
  }) {
    if (item.iuran.tipe != IuranType.insidentil) {
      jumlah = item.iuran.jumlah;
    }
  }

  String periode = "";
  int? jumlah;
  File? buktiFile;
  bool isLoading = false;
  bool isSuccess = false;
  String? errorMessage;

  void setJumlah(String value) {
    jumlah = int.tryParse(value);
    notifyListeners();
  }

  Future<void> pickBukti() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      buktiFile = File(picked.path);
      notifyListeners();
    }
  }

  Future<void> submit() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (buktiFile == null) {
        throw Exception("Bukti pembayaran wajib diupload");
      }

      if (jumlah == null || jumlah! <= 0) {
        throw Exception("Jumlah pembayaran tidak valid");
      }

      String? imageUrl;
      try {
        imageUrl = await cloudinaryService.uploadFile(
          buktiFile!,
          folder: "bukti_iuran",
        );
      } catch (_) {
        // Offline: imageUrl stays null, will use local path
      }

      final transaksi = Transaksi(
        iuranId: item.iuran.id!,
        keluargaId: keluargaId,
        jumlah: jumlah,
        waktuBayar: DateTime(
          selectedItem.bulan.year,
          selectedItem.bulan.month,
          1,
        ),
        status: StatusPembayaran.diproses,
        imgRef: imageUrl,
      );

      await iuranRepository.createTransaksi(
        transaksi,
        localFilePath: imageUrl == null ? buktiFile!.path : null,
      );

      isSuccess = true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    }

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    jumlah = item.iuran.tipe == IuranType.insidentil ? null : item.iuran.jumlah;

    buktiFile = null;
    errorMessage = null;
    isSuccess = false;

    notifyListeners();
  }
}
