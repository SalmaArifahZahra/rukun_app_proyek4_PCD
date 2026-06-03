import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/utils/colors_utils.dart';
import 'package:rukun_app_proyek4/views/pages/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOutCubic),
    );

    _mainController.forward().then((_) {
      _rotationController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingView()),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUtils.b500,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('assets/images/logo_base.png', width: 120),
                      RotationTransition(
                        turns: _rotationAnimation,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: Image.asset(
                            'assets/images/logo_orbit.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  Text(
                    "RUKUN APP",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Aplikasi Manajemen Warga",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}