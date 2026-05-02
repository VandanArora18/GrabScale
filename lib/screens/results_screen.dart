import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/measurement.dart';
import '../widgets/dimension_row.dart';
import '../services/pdf_service.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  final Measurement measurement;
  const ResultsScreen({super.key, required this.measurement});

  bool _isLocalPath(String? path) => path != null && !path.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.dashboard_outlined, color: AppColors.onSurface),
          onPressed: () => Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false)),
        title: Text('Measurement Result', style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        centerTitle: true,
        actions: [
          if (measurement.pdfUrl != null)
            IconButton(icon: const Icon(Icons.share_outlined, color: AppColors.onSurface),
              onPressed: () async {
                final pdfPath = measurement.pdfUrl!;
                if (File(pdfPath).existsSync()) {
                  await PdfService().sharePdf(pdfPath, text: 'My ScaleGrab Measurement - ${measurement.objectName}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF file not found on device')));
                }
              }),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          if (measurement.frontalImageUrl != null || measurement.sideImageUrl != null)
            Row(children: [
              if (measurement.frontalImageUrl != null) Expanded(child: _imageThumb(measurement.frontalImageUrl!, 'Frontal')),
              const SizedBox(width: 12),
              if (measurement.sideImageUrl != null) Expanded(child: _imageThumb(measurement.sideImageUrl!, 'Side')),
            ]),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.glassBackground, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: [BoxShadow(color: AppColors.electricCyan.withValues(alpha: 0.05), blurRadius: 20)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(measurement.objectName, style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.electricCyan)),
              const SizedBox(height: 20),
              DimensionRow(icon: '📏', label: 'Length', valueMm: measurement.lengthMm, color: const Color(0xFF50FF80)),
              DimensionRow(icon: '↕️', label: 'Height', valueMm: measurement.heightMm, color: const Color(0xFF50C8FF)),
              DimensionRow(icon: '↔️', label: 'Width', valueMm: measurement.widthMm, color: const Color(0xFFFFC850)),
              Divider(color: AppColors.outlineVariant, height: 32),
              _resultRow('🧊', 'Volume', '${measurement.volumeCm3.toStringAsFixed(1)} cm³'),
              _resultRow('📋', 'Surface Area', '${measurement.surfaceCm2.toStringAsFixed(1)} cm²'),
              if (measurement.shape != null)
                _resultRow('✨', 'Shape', measurement.shape![0].toUpperCase() + measurement.shape!.substring(1)),
              Divider(color: AppColors.outlineVariant, height: 32),
             
              Row(children: [
                Text('Fill Ratio', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
                const Spacer(),
                Text('${measurement.fillPct.toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.electricCyan)),
              ]),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: measurement.fillPct / 100),
                duration: const Duration(milliseconds: 1000),
                builder: (_, val, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: val, minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.electricCyan)))),
            ]),
          ),
          const SizedBox(height: 20),
        
          if (measurement.pdfUrl != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.glassBackground, borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder)),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(
                  color: AppColors.electricCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.picture_as_pdf, color: AppColors.electricCyan)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Measurement Report', style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  Text('PDF • Saved locally', style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ])),
                IconButton(icon: const Icon(Icons.share, color: AppColors.electricCyan),
                  onPressed: () async {
                    final pdfPath = measurement.pdfUrl!;
                    if (File(pdfPath).existsSync()) {
                      await PdfService().sharePdf(pdfPath);
                    }
                  }),
              ]),
            ),
        ]),
      )),
    );
  }

  Widget _imageThumb(String path, String label) {
    final isLocal = _isLocalPath(path);
    final fileExists = isLocal ? File(path).existsSync() : false;
    
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(16),
        child: AspectRatio(aspectRatio: 3/4,
          child: isLocal
            ? (fileExists
              ? Image.file(File(path), fit: BoxFit.cover)
              : Container(color: AppColors.surfaceContainerHigh,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.image_not_supported, color: AppColors.onSurfaceVariant, size: 24),
                    const SizedBox(height: 4),
                    Text('On another device', style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  ])))
            : Image.network(path, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceContainerHigh,
                  child: const Icon(Icons.image, color: AppColors.onSurfaceVariant))))),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
    ]);
  }

  Widget _resultRow(String icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      ]));
  }
}
