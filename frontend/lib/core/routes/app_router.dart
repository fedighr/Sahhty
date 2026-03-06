// lib/core/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/verify_code_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/profile_setup/screens/profile_selection_screen.dart';
import '../../features/profile_setup/screens/patient_setup_screen.dart';
import '../../features/profile_setup/screens/doctor_setup_screen.dart';
import '../../features/home/screens/patient_home_screen.dart';
import '../../features/home/screens/doctor_home_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash           = '/';
  static const String login            = '/login';
  static const String register         = '/register';
  static const String verifyCode       = '/verify-code';
  static const String forgotPassword   = '/forgot-password';
  static const String profileSelection = '/profile-selection';
  static const String patientSetup     = '/patient-setup';
  static const String doctorSetup      = '/doctor-setup';
  static const String patientHome      = '/patient-home';
  static const String doctorHome       = '/doctor-home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading || authState.isInitial;
      final loc = state.matchedLocation;

      // Never redirect during loading / splash
      if (isLoading || loc == AppRoutes.splash) return null;

      final publicRoutes = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.verifyCode,
        AppRoutes.forgotPassword,
      ];

      final isPublic = publicRoutes.contains(loc);

      if (!isAuth && !isPublic) return AppRoutes.login;
      if (isAuth && isPublic)   return AppRoutes.profileSelection;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login,
        pageBuilder: (_, s) => _fade(s, const LoginScreen())),
      GoRoute(path: AppRoutes.register,
        pageBuilder: (_, s) => _fade(s, const RegisterScreen())),
      GoRoute(
        path: AppRoutes.verifyCode,
        pageBuilder: (_, s) {
          final email = s.extra as String? ?? '';
          return _fade(s, VerifyCodeScreen(email: email));
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (_, s) => _fade(s, const ForgotPasswordScreen()),
      ),
      GoRoute(path: AppRoutes.profileSelection,
        pageBuilder: (_, s) => _fade(s, const ProfileSelectionScreen())),
      GoRoute(path: AppRoutes.patientSetup,
        pageBuilder: (_, s) {
          final email = s.extra as String? ?? '';
          return _fade(s, PatientSetupScreen(email: email));
        }),
      GoRoute(path: AppRoutes.doctorSetup,
        pageBuilder: (_, s) {
          final email = s.extra as String? ?? '';
          return _fade(s, DoctorSetupScreen(email: email));
        }),
      GoRoute(path: AppRoutes.patientHome,
        pageBuilder: (_, s) => _fade(s, const PatientHomeScreen())),
      GoRoute(path: AppRoutes.doctorHome,
        pageBuilder: (_, s) => _fade(s, const DoctorHomeScreen())),
    ],
  );
});

CustomTransitionPage<void> _fade(GoRouterState s, Widget child) {
  return CustomTransitionPage(
    key: s.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, c) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: c,
      ),
    ),
  );
}
