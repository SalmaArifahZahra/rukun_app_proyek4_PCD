import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/keluarga_model.dart';
import 'package:rukun_app_proyek4/models/warga_model.dart';
import 'package:rukun_app_proyek4/repositories/kk_repository.dart';
import 'package:rukun_app_proyek4/repositories/warga_repository.dart';

class DetailKKViewModel extends ChangeNotifier {
  final KKRepository repo;
  final WargaRepository wargaRepo;
  final int kkId;

  bool isLoadingAnggota = false;
  String? anggotaError;

  DetailKKViewModel({
    required this.repo,
    required this.wargaRepo,
    required this.kkId,
  });

  Keluarga? kk;

  bool isLoading = false;
  String? error;

  List<Warga> anggota = [];

  String _searchQuery = '';

  List<Warga> get filteredAnggota {
    if (_searchQuery.isEmpty) return anggota;
    final q = _searchQuery.toLowerCase();
    return anggota.where((w) => w.nama.toLowerCase().contains(q)).toList();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  bool isDeleting = false;

  Future<void> fetchAnggota() async {
    try {
      isLoadingAnggota = true;
      notifyListeners();

      anggota = await wargaRepo.getWargaByKeluarga(kkId);

      anggotaError = null;
    } catch (e) {
      anggotaError = e.toString();
    } finally {
      isLoadingAnggota = false;
      notifyListeners();
    }
  }

  Future<void> fetchDetail() async {
    try {
      isLoading = true;
      notifyListeners();

      kk = await repo.getKKById(kkId);

      anggota = await wargaRepo.getWargaByKeluarga(kkId);

      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteKK() async {
    try {
      isDeleting = true;
      error = null;

      notifyListeners();

      await repo.deleteKK(kkId);

      return true;
    } catch (e) {
      error = e.toString().replaceAll("Exception: ", "");

      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }
}
