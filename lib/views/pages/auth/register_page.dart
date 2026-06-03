import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/viewmodels/auth_viewmodel.dart';
import 'package:rukun_app_proyek4/views/pages/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nikController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nikController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    nikController.clear();
    passwordController.clear();
    confirmPasswordController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: ColorsUtils.lightgray,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "Buat Akun Baru",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorsUtils.b200,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Silahkan Daftar menggunakan NIK yang sudah terdaftar",
                    style: TextStyle(color: ColorsUtils.gray),
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
                  _inputField(
                    "Confirm Password",
                    Icons.lock_outline,
                    controller: confirmPasswordController,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    onToggle: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: vm.errorMessage == null
                        ? const SizedBox()
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: ColorsUtils.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              vm.errorMessage!,
                              style: const TextStyle(color: ColorsUtils.red),
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();

                              if (passwordController.text !=
                                  confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Password tidak sama"),
                                  ),
                                );
                                return;
                              }

                              await vm.register(
                                nikController.text,
                                passwordController.text,
                                confirmPasswordController.text,
                              );

                              if (!context.mounted) return;

                              if (vm.errorMessage == null &&
                                  vm.authData != null &&
                                  !vm.isLoading) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
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
                          : const Text(
                              "Daftar",
                              style: TextStyle(
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
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: "Sudah punya akun? ",
                          style: TextStyle(color: ColorsUtils.gray),
                          children: [
                            TextSpan(
                              text: "Masuk di sini",
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
