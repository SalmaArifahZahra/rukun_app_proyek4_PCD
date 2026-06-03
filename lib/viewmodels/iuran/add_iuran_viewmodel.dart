import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/iuran/iuran_model.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/models/rw_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';

class AddIuranViewModel extends ChangeNotifier {
  final IuranRepository repository;

  AddIuranViewModel(this.repository);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> createIuran({
    required String nama,
    int? jumlah,
    required String level,
    required RwModel rw,
    RtModel? rt,
    required IuranType tipe,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      final iuran = Iuran(
        nama: nama,
        jumlah: jumlah,
        level: level == "RT" ? IuranLevel.rt : IuranLevel.rw,
        rw: rw,
        rt: rt,
        tipe: tipe,
        isActive: true
      );

      await repository.createIuran(iuran);

      _successMessage = "Iuran berhasil dibuat";

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessage() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
