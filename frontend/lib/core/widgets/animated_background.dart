import 'package:flutter/material.dart';
import 'package:sahhty/core/theme/app_theme.dart';

/// A beautiful animated background widget that can optionally show the
/// mother_baby image with a gradient overlay.
class AnimatedBackground extends StatelessWidget {
  final bool showImage;
  final double imageOpacity;
  final Widget? child;
  final List<Color>? gradientColors;

  const AnimatedBackground({
    super.key,
    this.showImage = false,
    this.imageOpacity = 0.18,
    this.child,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          AppColors.primaryLight.withAlpha(153),
          AppColors.background,
          Colors.white,
        ];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient base
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Optional image
        if (showImage)
          Positioned.fill(
            child: Opacity(
              opacity: imageOpacity,
              child: Image.asset(
                'assets/images/mother_baby.png.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
        // Gradient overlay on top of image
        if (showImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryLight.withAlpha(128),
                    AppColors.background.withAlpha(217),
                    Colors.white.withAlpha(242),
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),
        if (child != null) child!,
      ],
    );
  }
}
