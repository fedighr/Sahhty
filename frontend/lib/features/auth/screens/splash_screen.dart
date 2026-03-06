// lib/features/auth/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6)));
    _ctrl.forward();

    // Ensure minimum splash time then navigate based on current state
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _navigate(ref.read(authNotifierProvider));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _navigate(AuthState state) {
    if (_navigated || !mounted) return;
    if (state.isInitial || state.isLoading) return; // still checking
    _navigated = true;
    if (state.isAuthenticated) {
      context.go(AppRoutes.patientHome);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also react immediately if state resolves before the 1800ms delay
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      _navigate(next);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.health_and_safety_rounded,
                      color: Colors.white, size: 52),
                ),
                const SizedBox(height: 20),
                const Text('Sahhty',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 6),
                const Text('Votre santé, notre priorité',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 0.5)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
