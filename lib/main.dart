import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surfaceContainerLow,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ScaleGrabApp());
}

class ScaleGrabApp extends StatelessWidget {
  const ScaleGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScaleGrab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.deepNavy,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.electricCyan,
          secondary: AppColors.secondary,
          error: AppColors.error,
          onSurface: AppColors.onSurface,
          onPrimary: AppColors.onPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceContainerHigh,
          contentTextStyle: GoogleFonts.inter(color: AppColors.onSurface),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
