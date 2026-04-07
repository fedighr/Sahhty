import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sahhty/core/theme/app_theme.dart';

/// Floating particles (hearts, circles, dots) that drift upwards with
/// sinusoidal horizontal motion — creates a dreamy, premium feel.
class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color? color;
  final double maxOpacity;

  const FloatingParticles({
    super.key,
    this.particleCount = 18,
    this.color,
    this.maxOpacity = 0.35,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _particles = List.generate(widget.particleCount, (_) => _generateParticle());
  }

  _Particle _generateParticle() {
    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 8 + 3,
      speed: _random.nextDouble() * 0.3 + 0.1,
      amplitude: _random.nextDouble() * 0.03 + 0.01,
      phase: _random.nextDouble() * 2 * pi,
      opacity: _random.nextDouble() * widget.maxOpacity * 0.7 + widget.maxOpacity * 0.3,
      isHeart: _random.nextDouble() > 0.6,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              progress: _controller.value,
              color: widget.color ?? AppColors.primary,
            ),
            size: Size.infinite,
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

class _Particle {
  double x, y, size, speed, amplitude, phase, opacity;
  bool isHeart;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.amplitude,
    required this.phase,
    required this.opacity,
    required this.isHeart,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed * 4 + p.phase) % 1.0;
      final y = (p.y - t) % 1.0;
      final x = p.x + sin((progress * p.speed * 8 + p.phase) * 2 * pi) * p.amplitude;

      final px = x * size.width;
      final py = y * size.height;

      // Fade near edges
      final edgeFade = (y < 0.1 ? y / 0.1 : y > 0.9 ? (1 - y) / 0.1 : 1.0).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withAlpha((p.opacity * edgeFade * 255).round())
        ..style = PaintingStyle.fill;

      if (p.isHeart) {
        _drawHeart(canvas, Offset(px, py), p.size, paint);
      } else {
        canvas.drawCircle(Offset(px, py), p.size / 2, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final s = size * 0.6;
    path.moveTo(center.dx, center.dy + s * 0.3);
    path.cubicTo(
      center.dx - s, center.dy - s * 0.3,
      center.dx - s * 0.5, center.dy - s,
      center.dx, center.dy - s * 0.4,
    );
    path.cubicTo(
      center.dx + s * 0.5, center.dy - s,
      center.dx + s, center.dy - s * 0.3,
      center.dx, center.dy + s * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
