// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _textFadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
    );
    _textFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainShell(),
              transitionDuration: const Duration(milliseconds: 500),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing hexagon logo
            ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '⬡',
                      style: TextStyle(fontSize: 50, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App name
            FadeTransition(
              opacity: _textFadeAnim,
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppColors.textMain,
                  ),
                  children: [
                    TextSpan(text: 'Manga'),
                    TextSpan(
                      text: 'Verse',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _textFadeAnim,
              child: const Text(
                'Lee sin límites',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
