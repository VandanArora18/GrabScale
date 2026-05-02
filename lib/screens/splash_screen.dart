import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../widgets/animated_cube.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigate();
    });
  }

  void _navigate() {
    final user = AuthService().currentUser;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => user != null ? const HomeScreen() : const LoginScreen()));
  }

  @override
  void dispose() { _progressController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          Positioned(top: -100, left: -100, child: Container(width: 400, height: 400,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.electricCyan.withOpacity(0.08), Colors.transparent])))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnimatedCube(size: 140),
                const SizedBox(height: 32),
                Text('ScaleGrab', style: GoogleFonts.plusJakartaSans(
                    fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white,
                    shadows: [Shadow(color: AppColors.electricCyan.withOpacity(0.5), blurRadius: 20)])),
                const SizedBox(height: 8),
                Text('Measure anything. Instantly.', style: GoogleFonts.inter(
                    fontSize: 16, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
          Positioned(bottom: 80, left: 40, right: 40,
            child: Column(children: [
              AnimatedBuilder(animation: _progressController, builder: (_, __) =>
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: _progressController.value,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.electricCyan), minHeight: 3))),
              const SizedBox(height: 16),
              Text('POWERED BY COMPUTER VISION', style: GoogleFonts.inter(
                  fontSize: 12, letterSpacing: 2, color: AppColors.onSurfaceVariant)),
            ])),
        ],
      ),
    );
  }
}
