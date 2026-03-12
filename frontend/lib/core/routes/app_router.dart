// lib/core/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/verify_code_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/profile_setup/screens/patient_setup_screen.dart';
import '../../features/profile_setup/screens/doctor_setup_screen.dart';
import '../../features/home/screens/patient_home_screen.dart';
import '../../features/home/screens/doctor_home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/pregnancy/screens/pregnancy_detail_screen.dart';
import '../../features/measurements/screens/measurements_screen.dart';
import '../../features/measurements/screens/add_measurement_screen.dart';
import '../../features/appointments/screens/appointments_list_screen.dart';
import '../../features/medications/screens/medications_list_screen.dart';
import '../../features/medical_files/screens/medical_files_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash         = '/';
  static const String login          = '/login';
  static const String register       = '/register';
  static const String verifyCode     = '/verify-code';
  static const String forgotPassword = '/forgot-password';
  static const String patientSetup   = '/patient-setup';
  static const String doctorSetup    = '/doctor-setup';
  static const String patientHome    = '/patient-home';
  static const String doctorHome     = '/doctor-home';

  // ── New Feature Routes ──────────────────────────────────────────────────
  static const String profile          = '/profile';
  static const String pregnancyDetail  = '/pregnancy';
  static const String measurements     = '/measurements';
  static const String addMeasurement   = '/measurements/add';
  static const String appointmentsList = '/appointments';
  static const String medicationsList  = '/medications';
  static const String medicalFiles     = '/medical-files';
  static const String alerts           = '/alerts';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, s) => _fade(s, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, s) => _fade(s, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.verifyCode,
        pageBuilder: (_, s) {
          final extra = s.extra;
          String email = '';
          bool isPasswordReset = false;
          if (extra is Map<String, dynamic>) {
            email           = extra['email']           as String? ?? '';
            isPasswordReset = extra['isPasswordReset'] as bool?   ?? false;
          } else if (extra is String) {
            email = extra;
          }
          return _fade(s, VerifyCodeScreen(
            email: email,
            isPasswordReset: isPasswordReset,
          ));
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (_, s) {
          final extra = s.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          final step  = extra?['step']  as String? ?? 'email';
          return _fade(s, ForgotPasswordScreen(
            initialEmail: email,
            initialStep: step,
          ));
        },
      ),
      GoRoute(
        path: AppRoutes.patientSetup,
        pageBuilder: (_, s) {
          final email = s.extra as String? ?? '';
          return _fade(s, PatientSetupScreen(email: email));
        },
      ),
      GoRoute(
        path: AppRoutes.doctorSetup,
        pageBuilder: (_, s) {
          final email = s.extra as String? ?? '';
          return _fade(s, DoctorSetupScreen(email: email));
        },
      ),
      GoRoute(
        path: AppRoutes.patientHome,
        pageBuilder: (_, s) => _fade(s, const PatientHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.doctorHome,
        pageBuilder: (_, s) => _fade(s, const DoctorHomeScreen()),
      ),

      // ── New Feature Routes ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (_, s) => _fade(s, const ProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.pregnancyDetail,
        pageBuilder: (_, s) => _fade(s, const PregnancyDetailScreen()),
      ),
      GoRoute(
        path: AppRoutes.measurements,
        pageBuilder: (_, s) => _fade(s, const MeasurementsScreen()),
      ),
      GoRoute(
        path: AppRoutes.addMeasurement,
        pageBuilder: (_, s) => _fade(s, const AddMeasurementScreen()),
      ),
      GoRoute(
        path: AppRoutes.appointmentsList,
        pageBuilder: (_, s) => _fade(s, const AppointmentsListScreen()),
      ),
      GoRoute(
        path: AppRoutes.medicationsList,
        pageBuilder: (_, s) => _fade(s, const MedicationsListScreen()),
      ),
      GoRoute(
        path: AppRoutes.medicalFiles,
        pageBuilder: (_, s) => _fade(s, const MedicalFilesScreen()),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        pageBuilder: (_, s) => _fade(s, const AlertsScreen()),
      ),
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
