import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/measurement.dart';

class MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback? onTap;

  const MeasurementCard({super.key, required this.measurement, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.electricCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(measurement.objectName,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.electricCyan, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 12),
            _dimRow('L', '${measurement.lengthMm.toStringAsFixed(1)} mm'),
            const SizedBox(height: 4),
            _dimRow('H', '${measurement.heightMm.toStringAsFixed(1)} mm'),
            const SizedBox(height: 4),
            _dimRow('W', '${measurement.widthMm.toStringAsFixed(1)} mm'),
            const Spacer(),
            Text(
              '${measurement.volumeCm3.toStringAsFixed(1)} cm³',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dimRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(value, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface.withOpacity(0.8))),
      ],
    );
  }
}
