import 'package:flutter/material.dart';

class KelolaProfileViewModel extends ChangeNotifier {
  final oldPasswordController = TextEditingController();

  final newPasswordController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  bool obscureOldPassword = true;

  bool obscureNewPassword = true;

  bool obscureConfirmPassword = true;

  bool isLoading = false;

  String? errorMessage;

  String? successMessage;

  void toggleOldPassword() {
    obscureOldPassword = !obscureOldPassword;

    notifyListeners();
  }

  void toggleNewPassword() {
    obscureNewPassword = !obscureNewPassword;

    notifyListeners();
  }

  void toggleConfirmPassword() {
    obscureConfirmPassword = !obscureConfirmPassword;

    notifyListeners();
  }

  Future<void> submit() async {
    isLoading = true;

    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    isLoading = false;

    successMessage = "belum tersedia";

    notifyListeners();
  }

  @override
  void dispose() {
    oldPasswordController.dispose();

    newPasswordController.dispose();

    confirmPasswordController.dispose();

    super.dispose();
  }
}
