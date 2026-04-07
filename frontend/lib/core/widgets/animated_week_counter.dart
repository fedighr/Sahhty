import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sahhty/core/theme/app_theme.dart';

/// An animated week counter that counts up from 0 to the target week
/// with a pulsing ring and glow effect.
class AnimatedWeekCounter extends StatelessWidget {
  final int weeks;
  final int? days;
  final double size;
  final Color? color;

  const AnimatedWeekCounter({
    super.key,
    required this.weeks,
    this.days,
    this.size = 120,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: weeks),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animatedWeek, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.withAlpha(38), width: 3),
                ),
              )
                  .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                  ),
              // Inner glow circle
              Container(
                width: size * 0.82,
                height: size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.withAlpha(30),
                      c.withAlpha(8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Number
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animatedWeek',
                    style: TextStyle(
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'semaines',
                    style: TextStyle(
                      fontSize: size * 0.11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(217),
                    ),
                  ),
                  if (days != null && days! > 0)
                    Text(
                      '+$days jour${days! > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: size * 0.09,
                        color: Colors.white.withAlpha(178),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
