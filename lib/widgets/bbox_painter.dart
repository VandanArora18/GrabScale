import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BboxPainter extends CustomPainter {
  final Rect? refRect;
  final Rect? tgtRect;
  final Rect? currentDrawing;
  final bool isDrawingRef;

  BboxPainter({this.refRect, this.tgtRect, this.currentDrawing, this.isDrawingRef = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (refRect != null) {
      _drawDashedRect(canvas, refRect!, AppColors.electricCyan, 'CARD');
    }
    if (tgtRect != null) {
      _drawDashedRect(canvas, tgtRect!, const Color(0xFFFF6B35), 'OBJECT');
    }
    if (currentDrawing != null) {
      final color = isDrawingRef ? AppColors.electricCyan : const Color(0xFFFF6B35);
      _drawDashedRect(canvas, currentDrawing!, color, isDrawingRef ? 'CARD' : 'OBJECT');
    }
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Glow
    canvas.drawRect(rect, glowPaint);

    // Dashed rect
    final path = Path()..addRect(rect);
    _drawDashedPath(canvas, path, paint);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bgRect = Rect.fromLTWH(rect.left, rect.top - 20, textPainter.width + 10, 18);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        Paint()..color = color.withOpacity(0.2));
    textPainter.paint(canvas, Offset(rect.left + 5, rect.top - 19));
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final len = 8.0;
        final gap = 5.0;
        final end = (distance + len).clamp(0.0, metric.length);
        final extracted = metric.extractPath(distance, end);
        canvas.drawPath(extracted, paint);
        distance += len + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BboxPainter oldDelegate) => true;
}
