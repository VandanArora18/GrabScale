import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../models/measurement.dart';
import '../widgets/animated_cube.dart';
import 'results_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final File frontalImage, sideImage;
  final String frontalRefBbox, frontalTgtBbox, sideRefBbox, sideTgtBbox;
  final String shape;
  const ProcessingScreen({super.key, required this.frontalImage, required this.sideImage,
    required this.frontalRefBbox, required this.frontalTgtBbox,
    required this.sideRefBbox, required this.sideTgtBbox, required this.shape});
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final _steps = [
    '→ Preprocessing image...',
    '→ Running GrabCut segmentation...',
    '→ Calibrating scale...',
    '→ Computing dimensions...',
    '→ Generating report...',
  ];
  int _currentStep = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animateSteps();
    _callApi();
  }

  Future<void> _animateSteps() async {
    while (mounted && _error == null) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _currentStep = (_currentStep + 1) % _steps.length);
    }
  }

  Future<void> _callApi() async {
    try {
      final api = ApiService();
      final data = await api.measure(
        frontalImage: widget.frontalImage, sideImage: widget.sideImage,
        frontalRefBbox: widget.frontalRefBbox, frontalTgtBbox: widget.frontalTgtBbox,
        sideRefBbox: widget.sideRefBbox, sideTgtBbox: widget.sideTgtBbox,
        shape: widget.shape);

      final uid = AuthService().currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final firestore = FirestoreService();
      final localStorage = LocalStorageService();
      final pdfService = PdfService();

      final count = await firestore.getMeasurementCount(uid);
      final objectName = 'Object #${count + 1}';
      final measurementId = DateTime.now().millisecondsSinceEpoch.toString();

      final frontalPath = await localStorage.saveImage(measurementId, 'frontal.jpg', widget.frontalImage);
      final sidePath = await localStorage.saveImage(measurementId, 'side.jpg', widget.sideImage);

      String? resultPath;
      if (data['result_image_b64'] != null) {
        final resultFile = await pdfService.saveImageFromBase64(data['result_image_b64'], 'result_$measurementId.jpg');
        resultPath = await localStorage.saveImage(measurementId, 'result.jpg', resultFile);
      }

      String? pdfPath;
      if (data['pdf_b64'] != null) {
        final pdfFile = await pdfService.savePdfFromBase64(data['pdf_b64'], 'report_$measurementId.pdf');
        pdfPath = await localStorage.saveImage(measurementId, 'report.pdf', pdfFile);
      }

      final measurement = Measurement(
        createdAt: DateTime.now(), objectName: objectName,
        lengthMm: (data['length_mm'] ?? 0).toDouble(),
        heightMm: (data['height_mm'] ?? 0).toDouble(),
        widthMm: (data['width_mm'] ?? 0).toDouble(),
        volumeCm3: (data['volume_cm3'] ?? 0).toDouble(),
        surfaceCm2: (data['surface_cm2'] ?? 0).toDouble(),
        fillPct: (data['fill_pct'] ?? 0).toDouble(),
        shape: data['shape'],
        frontalImageUrl: frontalPath, sideImageUrl: sidePath,
        resultImageUrl: resultPath, pdfUrl: pdfPath);

      final docRef = await firestore.addMeasurement(uid, measurement);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ResultsScreen(measurement: Measurement(
            id: docRef.id, createdAt: measurement.createdAt, objectName: objectName,
            lengthMm: measurement.lengthMm, heightMm: measurement.heightMm,
            widthMm: measurement.widthMm, volumeCm3: measurement.volumeCm3,
            surfaceCm2: measurement.surfaceCm2, fillPct: measurement.fillPct,
            shape: measurement.shape,
            frontalImageUrl: frontalPath, sideImageUrl: sidePath,
            resultImageUrl: resultPath, pdfUrl: pdfPath))));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const AnimatedCube(size: 120),
          const SizedBox(height: 40),
          Text('Analyzing your object...', style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
          const SizedBox(height: 24),
          if (_error == null) ...[
            AnimatedSwitcher(duration: const Duration(milliseconds: 300),
              child: Text(_steps[_currentStep], key: ValueKey(_currentStep),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.electricCyan))),
          ] else ...[
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)),
              child: Text(_error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurface,
                  side: BorderSide(color: AppColors.glassBorder)),
                child: const Text('GO BACK')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () { setState(() => _error = null); _callApi(); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricCyan, foregroundColor: AppColors.onPrimary),
                child: const Text('RETRY')),
            ]),
          ],
        ]),
      )),
    );
  }
}
