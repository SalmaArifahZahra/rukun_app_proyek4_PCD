import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/kegiatan_model.dart';
import 'package:rukun_app_proyek4/utils/status_utils.dart';

class KegiatanViewmodel extends ChangeNotifier {
  final List<Kegiatan> _all = [];

  bool isLoading = false;
  String? errorMessage;

  FilterKegiatanStatus selectedStatus =
      FilterKegiatanStatus.semua;

  List<Kegiatan> get data {
    if (selectedStatus ==
        FilterKegiatanStatus.semua) {
      return _all;
    }

    return _all
        .where(
          (e) =>
              e.uiStatus.type ==
              selectedStatus,
        )
        .toList();
  }

  void setStatus(
    FilterKegiatanStatus status,
  ) {
    selectedStatus = status;
    notifyListeners();
  }

  Future<void> loadKegiatan(
    List<Kegiatan> items,
  ) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      _all
        ..clear()
        ..addAll(items);
    } catch (e) {
      errorMessage =
          "Gagal memuat kegiatan";
    }

    isLoading = false;
    notifyListeners();
  }
}