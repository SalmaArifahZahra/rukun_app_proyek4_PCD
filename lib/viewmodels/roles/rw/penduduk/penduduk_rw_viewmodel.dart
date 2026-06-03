import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/models/rt_model.dart';
import 'package:rukun_app_proyek4/repositories/rtrw_repository.dart';

class RWPendudukViewmodel extends ChangeNotifier {
  final RTRWRepository repository;

  RWPendudukViewmodel({required this.repository});

  bool isLoading = false;
  String? errorMessage;

  List<RtModel> rtList = [];

  Future<void> init(int rwId) async {
    await loadRT(rwId);
  }

  Future<void> loadRT(int rwId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final rw = await repository.getRWById(rwId);

      rtList = rw?.rtList ?? [];
    } catch (e, stack) {
      errorMessage = e.toString();
      
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stack);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(int rwId) async {
    await loadRT(rwId);
  }
}
