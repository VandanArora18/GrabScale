import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class DimensionRow extends StatelessWidget {
  final String icon;
  final String label;
  final double valueMm;
  final Color? color;

  const DimensionRow({super.key, required this.icon, required this.label, required this.valueMm, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: valueMm),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return Text(
                '${val.toStringAsFixed(1)} mm',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: color ?? AppColors.onSurface),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            '(${(valueMm / 10).toStringAsFixed(2)} cm)',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
