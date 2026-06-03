import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/iuran/rw/iuran_detail_rw_model.dart';
import 'package:rukun_app_proyek4/repositories/iuran_repository.dart';

class IuranRWDetailViewModel extends ChangeNotifier {
  final IuranRepository repository;

  IuranRWDetailViewModel(this.repository);

  bool isLoading = false;
  String? errorMessage;

  IuranRWDetail? detail;

  Future<void> fetchDetail(int id) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await repository.getIuranRWDetail(id);

      detail = result;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
