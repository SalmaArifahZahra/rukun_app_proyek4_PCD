import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/iuran/keluarga_status_model.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/transaksi_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/repositories/rtrw_repository.dart';

class IuranBulananDetailViewModel extends ChangeNotifier {
  final IuranRepository iuranRepo;
  final RTRWRepository rtrwRepo;
  final KKRepository kkRepository;

  IuranBulananDetailViewModel({
    required this.iuranRepo,
    required this.rtrwRepo,
    required this.kkRepository,
  });

  bool isLoading = false;
  String? errorMessage;

  Iuran? iuran;
  RtModel? rtDetail;
  List<Transaksi> transaksi = [];

  int totalTerkumpul = 0;

  List<Keluarga> keluargaList = [];

  Future<void> fetchDetail(int iuranId, int rtId, DateTime month) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final iuranResult = await iuranRepo.getIuranById(iuranId);
      final rtResult = await rtrwRepo.getRTById(rtId);
      final kkResult = await kkRepository.getKKByRT(rtId);

      iuran = iuranResult;
      rtDetail = rtResult;
      keluargaList = kkResult;

      transaksi = iuranResult?.transaksi ?? [];

      _calculateMonth(month, rtId);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void _calculateMonth(DateTime month, int rtId) {
    final bulanTransaksi = transaksi.where((t) {
      final d = t.waktuBayar;
      if (d == null) return false;

      final isSameMonth = d.year == month.year && d.month == month.month;

      final isPaid = t.status == StatusPembayaran.dibayar;

      final isSameRT = t.keluarga?.rtId == rtId;

      return isSameMonth && isPaid && isSameRT;
    }).toList();

    totalTerkumpul = bulanTransaksi.fold<int>(
      0,
      (sum, e) => sum + (e.jumlah ?? 0),
    );
  }

  

  Future<void> fetchKK(int rtId) async {
    isLoading = true;
    notifyListeners();

    try {
      keluargaList = await kkRepository.getKKByRT(rtId);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  List<KeluargaStatus> getKeluargaStatus(DateTime month, int iuranId) {
    return keluargaList.map((kk) {
      final tx = transaksi.where((t) {
        final d = t.waktuBayar;

        if (d == null) return false;

        final isSameMonth = d.year == month.year && d.month == month.month;

        return isSameMonth && t.keluarga?.id == kk.id && t.iuranId == iuranId;
      }).toList();

      final data = tx.isNotEmpty ? tx.first : null;

      return KeluargaStatus(
        keluarga: kk,
        sudahBayar: data?.status == StatusPembayaran.dibayar,

        status: data?.status ?? StatusPembayaran.belumDibayar,

        nominal: data?.jumlah ?? 0,

        idTransaksi: data?.id,

        waktuBayar: data?.waktuBayar,

        disetujuiOleh: data?.disetujuiNama,

        imgBukti: data?.imgRef,
      );
    }).toList();
  }

  Future<bool> updateStatusTransaksi({
    required int transaksiId,
    required String status,
    String? catatan,
    int? disetujuiOleh,
    required int iuranId,
    required int rtId,
    required DateTime month,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final body = {
        "status": status,
        if (catatan != null) "catatan": catatan,
        if (disetujuiOleh != null) "disetujui_oleh": disetujuiOleh,
      };

      await iuranRepo.updateStatusTransaksi(transaksiId, body);

      await fetchDetail(iuranId, rtId, month);

      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
