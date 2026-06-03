import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/setoran_iuran_rt_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/repositories/rtrw_repository.dart';
import 'package:rukun_app_proyek4/repositories/setoran_iuran_repository.dart';
import 'package:rukun_app_proyek4/services/utils/cloudinary_service.dart';

class IuranRTDetailViewModel extends ChangeNotifier {
  final IuranRepository iuranRepo;
  final RTRWRepository rtrwRepo;
  final SetoranIuranRtRepository setoranRepository;
  final CloudinaryService cloudinaryService;

  IuranRTDetailViewModel({
    required this.iuranRepo,
    required this.rtrwRepo,
    required this.setoranRepository,
    required this.cloudinaryService,
  });

  File? buktiSetoran;

  bool isLoading = false;
  String? errorMessage;

  Iuran? iuran;
  RtModel? rtDetail;

  List<Transaksi> transaksi = [];

  int totalTerkumpul = 0;

  int get saldoKasRt => rtDetail?.saldoKas ?? 0;

  final Map<String, SetoranIuranRt?> setoranPerPeriode = {};

  Future<void> pickBuktiSetoran() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      buktiSetoran = File(picked.path);
      notifyListeners();
    }
  }

  Future<void> loadSetoranPeriode(int iuranId, int rtId, DateTime month) async {
    final periode = DateFormat('yyyy-MM').format(month);
    final key = "$iuranId-$rtId-$periode";

    try {
      final result = await setoranRepository.getSetoranByPeriode(
        iuranId,
        rtId,
        periode,
      );

      if (result != null && result.id != null) {
        setoranPerPeriode[key] = result;
      } else {
        // if no server result, check local cache for pending item
        final cached = await setoranRepository.getCachedSetoranRawByPeriode(
          iuranId,
          rtId,
          periode,
        );

        if (cached != null) {
          setoranPerPeriode[key] = SetoranIuranRt.fromJson(cached);
        } else {
          setoranPerPeriode[key] = null;
        }
      }
    } catch (_) {
      setoranPerPeriode[key] = null;
    }

    notifyListeners();
  }

  Future<void> fetchDetail(int iuranId, int rtId) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final result = await iuranRepo.getIuranById(iuranId);

      final rt = await rtrwRepo.getRTById(rtId);

      iuran = result;
      rtDetail = rt;

      final allTransaksi = result?.transaksi ?? [];

      transaksi = allTransaksi.where((t) {
        final keluarga = t.keluarga;

        return keluarga?.rtId == rtId;
      }).toList();

      totalTerkumpul = transaksi
          .where((t) => t.status == StatusPembayaran.dibayar)
          .fold<int>(0, (sum, item) => sum + (item.jumlah ?? 0));

      final semuaSetoran = await setoranRepository.getSetoranByIuranRT(
        iuranId,
        rtId,
      );

      for (final item in semuaSetoran) {
        final periode = item.periodeBulan;

        final key = "${item.iuranId}-${item.rtId}-$periode";
        setoranPerPeriode[key] = item;
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;

    notifyListeners();
  }

  Future<bool> createSetoran(
    SetoranIuranRt setoran, {
    String? localDocumentPath,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      notifyListeners();

      String? documentRef;

      // Try to upload locally if a path was provided (fast path)
      if (localDocumentPath != null) {
        try {
          final file = File(localDocumentPath);
          final uploaded = await cloudinaryService.uploadFile(
            file,
            folder: 'setoran_iuran_rt',
          );

          if (uploaded != null) {
            documentRef = uploaded;
            localDocumentPath = null; // uploaded, no need to keep local path
          }
        } catch (_) {
          // ignore and let repository handle enqueueing the local path
        }
      } else if (buktiSetoran != null) {
        try {
          final uploaded = await cloudinaryService.uploadFile(
            buktiSetoran!,
            folder: 'setoran_iuran_rt',
          );
          if (uploaded != null) {
            documentRef = uploaded;
          }
        } catch (_) {
          // ignore and let repository handle enqueueing
        }
      }

      final data = setoran.copyWith(documentRef: documentRef);

      await setoranRepository.createSetoran(
        data,
        localDocumentPath: localDocumentPath,
      );

      final periode = DateFormat('yyyy-MM').format(data.periodeBulan);
      final key = "${data.iuranId}-${data.rtId}-$periode";

      final refreshed = await setoranRepository.getSetoranByPeriode(
        data.iuranId,
        data.rtId,
        periode,
      );

      setoranPerPeriode[key] = refreshed;

      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveSetoran(int setoranId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await setoranRepository.approveSetoran(setoranId);

      // refresh data biar sinkron
      await _refreshSetoran(setoranId);

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectSetoran(int setoranId, String catatan) async {
    try {
      if (catatan.trim().isEmpty) {
        errorMessage = "Catatan penolakan wajib diisi";
        notifyListeners();
        return false;
      }

      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await setoranRepository.rejectSetoran(setoranId, catatan);

      await _refreshSetoran(setoranId);

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSetoran(int setoranId) async {
    final updated = await setoranRepository.getSetoranById(setoranId);

    if (updated == null) return;

    final periode = updated.periodeBulan;
    final key =
        "${updated.iuranId}-${updated.rtId}-${DateFormat('yyyy-MM').format(periode)}";

    setoranPerPeriode[key] = updated;

    notifyListeners();
  }

  Future<void> resetSetoranForm() async {
    buktiSetoran = null;
    notifyListeners();
  }

  String periodeKey(int iuranId, int rtId, DateTime month) {
    final periode = DateFormat('yyyy-MM').format(month);
    return "$iuranId-$rtId-$periode";
  }
}
