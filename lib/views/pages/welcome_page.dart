import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/views/pages/auth/login_page.dart';
import 'package:rukun_app_proyek4/views/pages/auth/register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUtils.b500,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Image.asset(
                          "assets/images/icon_rukun.png",
                          height: 190,
                        ),
                      ),
                      const SizedBox(height: 80),
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          "Selamat Datang\ndi RukunApp",
                          style: TextStyle(
                            color: ColorsUtils.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          "Pantau data penduduk, kelola iuran, dan informasi RT/RW dalam satu aplikasi",
                          style: TextStyle(
                            color: ColorsUtils.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsUtils.yellow,
                            foregroundColor: ColorsUtils.white,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text("Masuk"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsUtils.white,
                            foregroundColor: ColorsUtils.b400,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text("Daftar"),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}