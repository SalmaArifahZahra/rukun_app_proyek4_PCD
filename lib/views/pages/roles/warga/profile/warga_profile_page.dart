import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/utils/appbar_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/viewmodels/roles/warga/profile/kelola_profile_viewmodel.dart';

class KelolaProfilePage extends StatelessWidget {
  const KelolaProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthViewModel>().currentUser?.warga?.nama ?? "-";

    final vm = context.watch<KelolaProfileViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ColorsUtils.white,

      appBar: AppBarUtils.buildAppBar(
        context: context,
        name: nama,
        title: "Detail Profile",
        subtitle: "Ubah Kata Sandi anda",
        showName: false,
        showAvatar: false,
        showGreeting: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: ColorsUtils.b400.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 42,
                  color: ColorsUtils.b400,
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Ubah Kata Sandi",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Masukkan dan konfirmasikan kata sandi baru",
                textAlign: TextAlign.center,
                style: TextStyle(color: ColorsUtils.gray, height: 1.5),
              ),

              const SizedBox(height: 40),
              TextField(
                controller: vm.oldPasswordController,
                obscureText: vm.obscureOldPassword,
                decoration: InputDecoration(
                  labelText: "Password Lama",
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: ColorsUtils.lightgray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: vm.toggleOldPassword,
                    icon: Icon(
                      vm.obscureOldPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              TextField(
                controller: vm.newPasswordController,
                obscureText: vm.obscureNewPassword,
                decoration: InputDecoration(
                  labelText: "Password Baru",
                  prefixIcon: const Icon(Icons.lock_reset),
                  filled: true,
                  fillColor: ColorsUtils.lightgray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: vm.toggleNewPassword,
                    icon: Icon(
                      vm.obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              TextField(
                controller: vm.confirmPasswordController,
                obscureText: vm.obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password",
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  filled: true,
                  fillColor: ColorsUtils.lightgray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: vm.toggleConfirmPassword,
                    icon: Icon(
                      vm.obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "• Minimal 8 karakter\n• Gunakan kombinasi huruf dan angka",
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorsUtils.darkgray,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsUtils.b400,
                    foregroundColor: ColorsUtils.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: vm.isLoading
                      ? null
                      : () async {
                          await vm.submit();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(vm.successMessage ?? "Berhasil"),
                              ),
                            );
                          }
                        },
                  child: vm.isLoading
                      ? const CircularProgressIndicator(
                          color: ColorsUtils.white,
                        )
                      : const Text(
                          "Simpan Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
