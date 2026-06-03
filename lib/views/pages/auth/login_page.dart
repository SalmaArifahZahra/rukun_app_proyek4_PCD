import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/views/layouts/main_layout.dart';
import 'package:rukun_app_proyek4/views/pages/auth/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nikController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    nikController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  if (!Navigator.canPop(context)) return;
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
              ),

              const SizedBox(height: 10),

              const Text(
                "Selamat Datang ",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorsUtils.b400,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Silahkan Masuk dengan akun anda",
                style: TextStyle(color: ColorsUtils.black800),
              ),

              const SizedBox(height: 30),
              _inputField(
                "NIK",
                Icons.person_outline,
                controller: nikController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),
              _inputField(
                "Password",
                Icons.lock_outline,
                controller: passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),

              const SizedBox(height: 16),
              if (vm.errorMessage != null)
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: ColorsUtils.red),
                ),
              if (vm.isLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Tunggu ${vm.lockSeconds} detik sebelum mencoba lagi",
                    style: const TextStyle(color: ColorsUtils.o100),
                  ),
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (vm.isLoading || vm.isLocked)
                      ? null
                      : () async {
                          await vm.login(
                            nikController.text,
                            passwordController.text,
                          );

                          if (!context.mounted) return;

                          if (vm.errorMessage == null && vm.authData != null) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MainLayout(user: vm.authData!.user),
                              ),
                              (route) => false,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsUtils.yellow,
                    foregroundColor: ColorsUtils.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: ColorsUtils.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          vm.isLocked ? "Tunggu (${vm.lockSeconds})" : "Masuk",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Belum punya akun? ",
                      style: TextStyle(color: ColorsUtils.gray),
                      children: [
                        TextSpan(
                          text: "Daftar di sini",
                          style: TextStyle(
                            color: ColorsUtils.b200,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  static Widget _inputField(
    String hint,
    IconData icon, {
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: ColorsUtils.gray),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggle,
              )
            : null,

        filled: true,
        fillColor: ColorsUtils.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
