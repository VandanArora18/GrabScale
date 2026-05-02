import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(color: AppColors.electricCyan.withOpacity(0.05), blurRadius: 20),
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.electricCyan.withOpacity(0.2),
                  AppColors.deepViolet.withOpacity(0.1),
                ]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.electricCyan, size: 24),
            ),
            const Spacer(),
            Text(title, style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
