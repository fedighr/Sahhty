import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/auth/screens/login_screen.dart';
import 'package:sahhty/features/auth/screens/register_screen.dart';
import 'package:sahhty/features/auth/screens/verify_code_screen.dart';
import 'package:sahhty/features/auth/screens/forgot_password_screen.dart';
import 'package:sahhty/features/auth/screens/patient_setup_screen.dart';
import 'package:sahhty/features/splash/screens/splash_screen.dart';
import 'package:sahhty/features/home/screens/main_shell.dart';
import 'package:sahhty/features/home/screens/patient_home_screen.dart';
import 'package:sahhty/features/measurements/screens/measurements_screen.dart';
import 'package:sahhty/features/measurements/screens/add_measurement_screen.dart';
import 'package:sahhty/features/pregnancy/screens/pregnancy_screen.dart';
import 'package:sahhty/features/alerts/screens/alerts_screen.dart';
import 'package:sahhty/features/profile/screens/profile_screen.dart';
import 'package:sahhty/features/doctors/screens/doctors_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/verify' ||
          location == '/forgot-password' ||
          location == '/patient-setup' ||
          location == '/splash';

      if (authState.status == AuthStatus.authenticated && isAuthRoute && location != '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return VerifyCodeScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/patient-setup',
        builder: (context, state) {
          final extras = state.extra as Map<String, String>? ?? {};
          return PatientSetupScreen(
            email: extras['email'] ?? '',
            gender: extras['gender'] ?? 'F',
          );
        },
      ),

      // ── Main app (bottom nav shell) ─────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: PatientHomeScreen()),
          ),
          GoRoute(
            path: '/measurements',
            pageBuilder: (context, state) => const NoTransitionPage(child: MeasurementsScreen()),
          ),
          GoRoute(
            path: '/pregnancy',
            pageBuilder: (context, state) => const NoTransitionPage(child: PregnancyScreen()),
          ),
          GoRoute(
            path: '/alerts',
            pageBuilder: (context, state) => const NoTransitionPage(child: AlertsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      GoRoute(
        path: '/add-measurement',
        builder: (context, state) => const AddMeasurementScreen(),
      ),
      GoRoute(
        path: '/doctors',
        builder: (context, state) => const DoctorsListScreen(),
      ),
    ],
  );
});
