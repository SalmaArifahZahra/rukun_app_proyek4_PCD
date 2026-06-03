import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/pengajuan_surat_model.dart';
import 'package:rukun_app_proyek4/repositories/surat_repository.dart';

enum FilterSurat { semua, diajukan, disetujui, ditolak, selesai }

class PengajuanSuratViewModel extends ChangeNotifier {
  final SuratRepository repository;
  List<PengajuanSurat> get filteredList => _filteredList;
  PengajuanSuratViewModel(this.repository);

  bool isLoading = false;
  String? errorMessage;

  final List<PengajuanSurat> _list = [];
  List<PengajuanSurat> get list => _filteredList;

  FilterSurat selectedFilter = FilterSurat.semua;

  Future<void> fetchSuratSaya() async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final result = await repository.getSuratSaya();

      _list
        ..clear()
        ..addAll(result);
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    }

    isLoading = false;
    notifyListeners();
  }

  void setFilter(FilterSurat f) {
    selectedFilter = f;
    notifyListeners();
  }

  List<PengajuanSurat> get _filteredList {
    if (selectedFilter == FilterSurat.semua) return _list;

    return _list.where((e) {
      switch (selectedFilter) {
        case FilterSurat.diajukan:
          return e.status == SuratStatus.diajukan;
        case FilterSurat.disetujui:
          return e.status == SuratStatus.disetujui;
        case FilterSurat.ditolak:
          return e.status == SuratStatus.ditolak;
        case FilterSurat.selesai:
          return e.status == SuratStatus.selesai;
        default:
          return true;
      }
    }).toList();
  }

  // total per status
  int get totalDiajukan =>
      _list.where((e) => e.status == SuratStatus.diajukan).length;

  int get totalDisetujui =>
      _list.where((e) => e.status == SuratStatus.disetujui).length;

  int get totalDitolak =>
      _list.where((e) => e.status == SuratStatus.ditolak).length;

  int get totalSelesai =>
      _list.where((e) => e.status == SuratStatus.selesai).length;

  // simpan surat
  Future<bool> submit(PengajuanSurat data) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final success = await repository.createSurat(data);

      if (success) {
        _list.insert(
          0,
          data.copyWith(
            id: -DateTime.now().microsecondsSinceEpoch,
            syncStatus: 'pending',
            waktuDibuat: DateTime.now(),
            waktuDiubah: DateTime.now(),
          ),
        );

        notifyListeners();
      }

      isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");

      isLoading = false;
      notifyListeners();

      return false;
    }
  }

  Future<bool> updateSurat(int id, PengajuanSurat data) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final body = {
        "keperluan": data.keperluan,
        "keterangan": data.keterangan,
        "status": data.status.value,
      };

      await repository.updateSurat(id, body);

      await fetchSuratSaya();

      isLoading = false;

      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");

      isLoading = false;

      notifyListeners();

      return false;
    }
  }

  Future<bool> deleteSurat(int id) async {
    try {
      await repository.deleteSurat(id);

      _list.removeWhere((e) => e.id == id);

      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");

      notifyListeners();

      return false;
    }
  }
}
