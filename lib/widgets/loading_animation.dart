import 'package:flutter/material.dart';
import '../constants/colors.dart';

class LoadingAnimation extends StatefulWidget {
  final String? message;
  const LoadingAnimation({super.key, this.message});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.electricCyan.withOpacity(0.3), width: 3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _controller.value * 6.28,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.transparent, width: 3),
                        gradient: SweepGradient(colors: [
                          Colors.transparent,
                          AppColors.electricCyan,
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(widget.message!, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
        ],
      ],
    );
  }
}
