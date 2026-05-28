import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/core/providers/locale_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final langSelected =
        await ref.read(localeProvider.notifier).isLanguageSelected();
    if (!mounted) return;
    if (!langSelected) {
      context.go('/language');
      return;
    }
    try {
      await ref.read(authProvider.notifier).checkAuth().timeout(
            const Duration(seconds: 5),
            onTimeout: () {},
          );
    } catch (_) {}
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      context.go(auth.role == 'D' ? '/doctor-home' : '/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE8F4FD),
              Color(0xFFD0E8F8),
              Color(0xFFBBDAF3),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2196F3).withAlpha(20),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1565C0).withAlpha(15),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LogoWidget(pulseController: _pulseController),
                  const SizedBox(height: 36),
                  const Text(
                    'Sahhty',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Color(0xFF1565C0),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut)
                      .then()
                      .shimmer(
                          duration: 1800.ms,
                          color: const Color(0xFF64B5F6)),
                  const SizedBox(height: 10),
                  const Text(
                    'Votre santé, notre priorité',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1976D2),
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 600.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withAlpha(200),
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .slideY(
                              begin: 0,
                              end: -0.8,
                              duration: 500.ms,
                              delay: (i * 160).ms,
                              curve: Curves.easeInOut)
                          .then()
                          .slideY(
                              begin: -0.8,
                              end: 0,
                              duration: 500.ms,
                              curve: Curves.easeInOut);
                    }),
                  ).animate().fadeIn(delay: 1200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoWidget extends StatefulWidget {
  final AnimationController pulseController;
  const _LogoWidget({required this.pulseController});

  @override
  State<_LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<_LogoWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.pulseController,
      builder: (context, child) {
        final glow = widget.pulseController.value;
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3)
                    .withAlpha((30 + glow * 40).toInt()),
                blurRadius: 30 + glow * 20,
                spreadRadius: 5 + glow * 5,
              ),
              BoxShadow(
                color: Colors.white.withAlpha(200),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo2.png',
              width: 160,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => const Icon(
                Icons.favorite,
                size: 80,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
        );
      },
    ).animate().scale(
          delay: 100.ms,
          duration: 600.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.6, 0.6),
        );
  }
}
