
import 'package:flutter/material.dart';

import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/repositories/surat_repository.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';

enum SuratFilterStatus { semua, diajukan, disetujui, ditolak, selesai }

class SuratListViewModel extends ChangeNotifier {
  final WargaRepository wargaRepo;
  final SuratRepository suratRepo;
  final AuthViewModel authVm;

  SuratListViewModel(
    this.wargaRepo,
    this.suratRepo,
    this.authVm,
  );

  bool isLoading = false;

  String searchQuery = "";
  SuratFilterStatus selectedStatus = SuratFilterStatus.semua;

  final List<PengajuanSurat> _allData = [];
  final Map<int, Warga> _wargaMap = {};


  List<PengajuanSurat> get data {
    var result = _filterByStatus(accessibleData);
    result = _filterBySearch(result);

    return result;
  }

  int get totalDitolak =>
      _allData.where((e) => e.status == SuratStatus.ditolak).length;

  int get totalDisetujui =>
      _allData.where((e) => e.status == SuratStatus.disetujui).length;

  int get totalSelesai =>
      _allData.where((e) => e.status == SuratStatus.selesai).length;

  int get totalDiajukan =>
      _allData.where((e) => e.status == SuratStatus.diajukan).length;

  int get totalSemua => _allData.length;

  List<PengajuanSurat> _filterByStatus(List<PengajuanSurat> source) {
    switch (selectedStatus) {
      case SuratFilterStatus.diajukan:
        return source.where((e) => e.status == SuratStatus.diajukan).toList();

      case SuratFilterStatus.disetujui:
        return source.where((e) => e.status == SuratStatus.disetujui).toList();

      case SuratFilterStatus.selesai:
        return source.where((e) => e.status == SuratStatus.selesai).toList();

      case SuratFilterStatus.ditolak:
        return source.where((e) => e.status == SuratStatus.ditolak).toList();

      case SuratFilterStatus.semua:
        return source;
    }
  }

  List<PengajuanSurat> _filterBySearch(List<PengajuanSurat> source) {
    if (searchQuery.trim().isEmpty) return source;

    final query = searchQuery.toLowerCase().trim();

    return source.where((e) {
      final namaWarga = getNamaWarga(e.wargaId ?? 0).toLowerCase();
      final keperluan = e.keperluan.toLowerCase();
      final keterangan = (e.keterangan ?? '').toLowerCase();

      return keperluan.contains(query) ||
          keterangan.contains(query) ||
          namaWarga.contains(query);
    }).toList();
  }

  Future<void> _loadWarga() async {
    try {
      final list = await wargaRepo.getAllWarga();

      _wargaMap.clear();

      for (final w in list) {
        if (w.id != null) {
          _wargaMap[w.id!] = w;
        }
      }
    } catch (e) {
      debugPrint("ERROR LOAD WARGA: $e");
    }
  }

  Warga? getWarga(int wargaId) => _wargaMap[wargaId];

  String getNamaWarga(int wargaId) => _wargaMap[wargaId]?.nama ?? "Warga";

  String getNikWarga(int wargaId) => _wargaMap[wargaId]?.nik ?? "-";

  String getAvatarInitial(int wargaId) {
    final nama = getNamaWarga(wargaId);

    return nama.isNotEmpty ? nama[0].toUpperCase() : "?";
  }

  /// Mencari URL template dari surat yang sudah Selesai (is_signed = true).
  /// Template ini bisa diunduh oleh RT sebagai referensi pembuatan surat baru.
  String? getTemplateUrl() {
    final selesai = _allData
        .where((e) => e.status == SuratStatus.selesai && e.docRef != null)
        .toList();

    if (selesai.isEmpty) return null;

    // Ambil yang paling baru (waktu diubah terbaru)
    selesai.sort((a, b) {
      final aTime = a.waktuDiubah ?? DateTime(0);
      final bTime = b.waktuDiubah ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    return selesai.first.docRef;
  }

  Future<void> fetchSurat({required int rwId}) async {
    try {
      isLoading = true;
      notifyListeners();

      await _loadWarga();

      final result = await suratRepo.getSuratByRw(rwId);

      _allData.clear();
      _allData.addAll(result);
    } catch (e) {
      debugPrint("ERROR FETCH SURAT: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<PengajuanSurat> get accessibleData {
    final user = authVm.currentUser;

    if (user?.pengurus?.level == "RW") {
      return _allData;
    }

    if (user?.pengurus?.level == "RT") {
      final rtId = user?.rt?.id ?? user?.pengurus?.rtId;

      return _allData.where((e) {
        final wRtId = e.rtId ?? getWarga(e.wargaId ?? 0)?.keluarga?.rtId;
        return wRtId == rtId;
      }).toList();
    }

    return [];
  }

  void setStatus(SuratFilterStatus status) {
    selectedStatus = status;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  /// Diperbarui agar bisa dipanggil dari Action ViewModel
  void updateSuratLocal({
    required int id,
    SuratStatus? status,
    String? docRef,
    bool? isSigned,
    String? catatan,
  }) {
    final index = _allData.indexWhere((e) => e.id == id);

    if (index == -1) return;

    _allData[index] = _allData[index].copyWith(
      status: status,
      docRef: docRef ?? _allData[index].docRef,
      isSigned: isSigned ?? _allData[index].isSigned,
      catatan: catatan ?? _allData[index].catatan,
    );

    notifyListeners();
  }

  String formatDate(DateTime? date) {
    if (date == null) return "-";

    return "${date.day}/${date.month}/${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> refresh({required int rwId}) async {
    await fetchSurat(rwId: rwId);
  }
}
