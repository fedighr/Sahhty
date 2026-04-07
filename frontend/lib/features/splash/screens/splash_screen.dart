import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );
    _fadeController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      await ref.read(authProvider.notifier).checkAuth().timeout(
            const Duration(seconds: 5),
            onTimeout: () {},
          );
    } catch (_) {}
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background with image
          const AnimatedBackground(showImage: true, imageOpacity: 0.18),

          // Floating particles
          const FloatingParticles(particleCount: 25, maxOpacity: 0.3),

          // Main content
          _SplashAnimatedBuilder(
            listenable: _fadeController,
            builder: (context, _) {
              return Opacity(
                opacity: _fadeAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing heart logo
                        _SplashAnimatedBuilder(
                          listenable: _pulseController,
                          builder: (context, _) {
                            final scale = 1.0 + _pulseController.value * 0.08;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primary.withAlpha(51),
                                      AppColors.primary.withAlpha(13),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha((51 + _pulseController.value * 25).toInt()),
                                      blurRadius: 30 + _pulseController.value * 10,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.favorite, size: 64, color: AppColors.primary),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // App name with shimmer
                        Text(
                          'Sahhty',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                fontSize: 38,
                              ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.3, curve: Curves.easeOut)
                            .then()
                            .shimmer(duration: 1800.ms, color: AppColors.primaryLight),

                        const SizedBox(height: 10),

                        Text(
                          'Votre santé, notre priorité',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                        ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.2),

                        const SizedBox(height: 56),

                        // Bouncing dots loader
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(178),
                                shape: BoxShape.circle,
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat())
                                .slideY(begin: 0, end: -0.8, duration: 500.ms, delay: (i * 150).ms, curve: Curves.easeInOut)
                                .then()
                                .slideY(begin: -0.8, end: 0, duration: 500.ms, curve: Curves.easeInOut);
                          }),
                        ).animate().fadeIn(delay: 1200.ms),
                      ],
                    ),
                  ),
                ),
              );
              },
            ),
        ],
      ),
    );
  }
}

class _SplashAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  const _SplashAnimatedBuilder({required super.listenable, required this.builder});
  @override
  Widget build(BuildContext context) => builder(context, null);
}
