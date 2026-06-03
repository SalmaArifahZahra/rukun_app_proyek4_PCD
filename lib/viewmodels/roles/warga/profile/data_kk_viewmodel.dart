import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';

class DataKKViewModel extends ChangeNotifier {
  final KKRepository kkRepository;
  final WargaRepository wargaRepository;

  DataKKViewModel({required this.kkRepository, required this.wargaRepository});

  bool isLoading = false;

  String? errorMessage;

  Keluarga? keluarga;

  Warga? currentWarga;

  List<Warga> anggotaKeluarga = [];

  Future<void> loadData({
    required int keluargaId,
    required Warga wargaLogin,
  }) async {
    try {
      isLoading = true;

      notifyListeners();
      currentWarga = wargaLogin;
      keluarga = await kkRepository.getKKById(keluargaId);
      anggotaKeluarga = await wargaRepository.getWargaByKeluarga(keluargaId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }
}
