import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AnimatedCube extends StatefulWidget {
  final double size;
  const AnimatedCube({super.key, this.size = 120});

  @override
  State<AnimatedCube> createState() => _AnimatedCubeState();
}

class _AnimatedCubeState extends State<AnimatedCube> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CubePainter(_controller.value),
        );
      },
    );
  }
}

class _CubePainter extends CustomPainter {
  final double progress;
  _CubePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricCyan
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AppColors.electricCyan.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.35;
    final angle = progress * 2 * pi;
    final cosA = cos(angle);
    final sinA = sin(angle);

    List<Offset> project(List<List<double>> vertices) {
      return vertices.map((v) {
        final x = v[0] * cosA - v[2] * sinA;
        final z = v[0] * sinA + v[2] * cosA;
        final scale = 1.0 / (1.0 + z / (s * 4));
        return Offset(cx + x * scale, cy + v[1] * scale);
      }).toList();
    }

    final verts = [
      [-s, -s, -s], [s, -s, -s], [s, s, -s], [-s, s, -s],
      [-s, -s, s], [s, -s, s], [s, s, s], [-s, s, s],
    ];

    final pts = project(verts);
    final edges = [
      [0,1],[1,2],[2,3],[3,0],
      [4,5],[5,6],[6,7],[7,4],
      [0,4],[1,5],[2,6],[3,7],
    ];

    for (final e in edges) {
      canvas.drawLine(pts[e[0]], pts[e[1]], glowPaint);
      canvas.drawLine(pts[e[0]], pts[e[1]], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CubePainter oldDelegate) => true;
}
