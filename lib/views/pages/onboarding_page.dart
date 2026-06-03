import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:rukun_app_proyek4/middleware/auth_gate.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "animation": "assets/animation/welcome.json",
      "title": "Selamat Datang di RukunApp",
      "desc":
          "Aplikasi pengelolaan data kependudukan, kegiatan, iuran, dan layanan surat untuk RT, RW, dan warga.",
    },
    {
      "animation": "assets/animation/analytic.json",
      "title": "Kelola Data & Kegiatan",
      "desc":
          "RT dan RW dapat mengatur data warga, kegiatan lingkungan, serta informasi penting dengan lebih mudah dan terstruktur.",
    },
    {
      "animation": "assets/animation/pay.json",
      "title": "Layanan Digital untuk Warga",
      "desc":
          "Warga dapat membayar iuran, melihat kegiatan, dan mengajukan surat langsung melalui aplikasi kapan saja.",
    },
  ];

  void nextPage() {
    if (currentPage == onboardingData.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
  }

  Widget buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        onboardingData.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 12 : 8,
          height: currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            color: currentPage == index ? Colors.blue : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final item = onboardingData[index];

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(item["animation"]!, height: 260),

                      const SizedBox(height: 30),
                      Text(
                        item["title"]!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        item["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Row(
              children: [
                Expanded(child: Center(child: buildIndicator())),

                GestureDetector(
                  onTap: nextPage,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentPage == onboardingData.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
