import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/auth/screens/login_screen.dart';
import 'package:sahhty/features/auth/screens/register_screen.dart';
import 'package:sahhty/features/auth/screens/verify_code_screen.dart';
import 'package:sahhty/features/auth/screens/verify_2fa_screen.dart';
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
import 'package:sahhty/features/doctors/screens/doctor_detail_screen.dart';
import 'package:sahhty/features/appointments/screens/appointments_screen.dart';
import 'package:sahhty/features/medications/screens/medications_screen.dart';
import 'package:sahhty/features/settings/screens/settings_screen.dart';
import 'package:sahhty/features/settings/screens/edit_profile_screen.dart';
import 'package:sahhty/features/settings/screens/edit_medical_screen.dart';
import 'package:sahhty/features/settings/screens/edit_menstrual_screen.dart';
import 'package:sahhty/features/settings/screens/edit_pregnancy_screen.dart';
import 'package:sahhty/features/settings/screens/change_password_screen.dart';
import 'package:sahhty/features/smartwatch/screens/smartwatch_screen.dart';
import 'package:sahhty/features/language/screens/language_selection_screen.dart';
import 'package:sahhty/features/auth/screens/doctor_setup_screen.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';
import 'package:sahhty/features/home/screens/doctor_shell.dart';
import 'package:sahhty/features/settings/screens/doctor_settings_screen.dart';
import 'package:sahhty/features/doctors/screens/doctor_schedule_screen.dart';

import '../../features/settings/screens/doctor_edit_profile_screen.dart';
import 'package:sahhty/features/settings/screens/medical_files_screen.dart';
import 'package:sahhty/features/settings/screens/doctor_medical_access_screen.dart';
import 'package:sahhty/features/settings/screens/patient_doctor_access_screen.dart';
import 'package:sahhty/features/alerts/screens/doctor_alerts_screen.dart';
import 'package:sahhty/features/doctors/screens/doctors_map_screen.dart';
import 'package:sahhty/features/doctors/screens/doctor_location_screen.dart';

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
          location == '/verify-2fa' ||
          location == '/forgot-password' ||
          location == '/patient-setup' ||
          location == '/doctor-setup' ||
          location == '/splash';

      if (authState.status == AuthStatus.authenticated && isAuthRoute && location != '/splash') {
        // Redirect to role-specific home
        return authState.role == 'D' ? '/doctor-home' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
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
        path: '/verify-2fa',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return Verify2FAScreen(email: email);
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
      GoRoute(
        path: '/doctor-setup',
        builder: (context, state) {
          final extras = state.extra as Map<String, String>? ?? {};
          return DoctorSetupScreen(
            email: extras['email'] ?? '',
            userId: int.tryParse(extras['userId'] ?? '') ?? 0,
          );
        },
      ),

      // ── Doctor app (bottom nav shell) ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DoctorShell(child: child),
        routes: [
          GoRoute(
            path: '/doctor-home',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorHomeScreen()),
          ),
          GoRoute(
            path: '/doctor-appointments',
            pageBuilder: (context, state) => const NoTransitionPage(child: AppointmentsScreen()),
          ),
          GoRoute(
            path: '/doctor-alerts',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorAlertsScreen()),
          ),
          GoRoute(
            path: '/doctor-settings',
            pageBuilder: (context, state) => const NoTransitionPage(child: DoctorSettingsScreen()),
          ),
        ],
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
          GoRoute(
            path: '/appointments',
            pageBuilder: (context, state) => const NoTransitionPage(child: AppointmentsScreen()),
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
      GoRoute(
        path: '/doctors/map',
        builder: (context, state) => const DoctorsMapScreen(),
      ),
      GoRoute(
        path: '/doctor/location',
        builder: (context, state) => const DoctorLocationScreen(),
      ),
      GoRoute(
        path: '/doctors/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final extra = state.extra as Map<String, dynamic>?;
          return DoctorDetailScreen(doctorId: id, initialData: extra);
        },
      ),
      GoRoute(
        path: '/medications',
        builder: (context, state) => const MedicationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings/edit-medical',
        builder: (context, state) => const EditMedicalScreen(),
      ),
      GoRoute(
        path: '/settings/edit-menstrual',
        builder: (context, state) => const EditMenstrualScreen(),
      ),
      GoRoute(
        path: '/settings/edit-pregnancy',
        builder: (context, state) => const EditPregnancyScreen(),
      ),
      GoRoute(
        path: '/settings/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/settings/medical-files',
        builder: (context, state) => const MedicalFilesScreen(),
      ),
      GoRoute(
        path: '/settings/doctor-access',
        builder: (context, state) => const PatientDoctorAccessScreen(),
      ),
      GoRoute(
        path: '/doctor/medical-access',
        builder: (context, state) => const DoctorMedicalAccessScreen(),
      ),
      GoRoute(
        path: '/doctor/edit-profile',
        builder: (context, state) => const DoctorEditProfileScreen(),
      ),
      GoRoute(
        path: '/doctor-schedule',
        builder: (context, state) => const DoctorScheduleScreen(),
      ),
      GoRoute(
        path: '/smartwatch',
        builder: (context, state) => const SmartwatchScreen(),
      ),
    ],
  );
});
