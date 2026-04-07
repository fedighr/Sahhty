import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sahhty/core/theme/app_theme.dart';

/// Animated wave clipper for decorative headers / banners.
class AnimatedWave extends StatefulWidget {
  final double height;
  final Color? color;
  final int waveCount;

  const AnimatedWave({
    super.key,
    this.height = 60,
    this.color,
    this.waveCount = 2,
  });

  @override
  State<AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary.withAlpha(20);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: double.infinity,
            height: widget.height,
            child: Stack(
              children: List.generate(widget.waveCount, (i) {
                final opacity = 1.0 - (i * 0.3);
                return ClipPath(
                  clipper: _WaveClipper(
                    progress: (_controller.value + i * 0.3) % 1.0,
                    waveHeight: widget.height * 0.4 * (1 - i * 0.2),
                  ),
                  child: Container(color: color.withAlpha(((color.a * 255.0).round().clamp(0, 255) * opacity).round())),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  const AnimatedBuilder({super.key, required Animation<double> animation, required this.builder})
      : super(listenable: animation);
  @override
  Widget build(BuildContext context) => builder(context, null);
}

class _WaveClipper extends CustomClipper<Path> {
  final double progress;
  final double waveHeight;

  _WaveClipper({required this.progress, required this.waveHeight});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          sin((x / size.width * 2 * pi) + (progress * 2 * pi)) * waveHeight * 0.5 +
          sin((x / size.width * 4 * pi) + (progress * 3 * pi)) * waveHeight * 0.2;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => old.progress != progress;
}
