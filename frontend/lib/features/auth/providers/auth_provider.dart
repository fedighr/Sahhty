import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/data/services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, needsVerification, needsProfileSetup, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? email;
  final String? role;
  final String? userId;
  final String? patientId;
  final String? doctorId;
  final String? name;
  final String? gender;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.email,
    this.role,
    this.userId,
    this.patientId,
    this.doctorId,
    this.name,
    this.gender,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? email,
    String? role,
    String? userId,
    String? patientId,
    String? doctorId,
    String? name,
    String? gender,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      email: email ?? this.email,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      debugPrint('AuthProvider: checking isLoggedIn...');
      final isLoggedIn = await _authService.isLoggedIn();
      debugPrint('AuthProvider: isLoggedIn = $isLoggedIn');
      if (isLoggedIn) {
        final info = await _authService.getStoredUserInfo();
        debugPrint('AuthProvider: user info = $info');
        state = AuthState(
          status: AuthStatus.authenticated,
          email: info['email'],
          name: info['name'],
          role: info['role'],
          userId: info['userId'],
          patientId: info['patientId'],
          doctorId: info['doctorId'],
          gender: info['gender'],
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('AuthProvider: checkAuth error: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _authService.signin(email, password);

    if (result['success'] == true) {
      final info = await _authService.getStoredUserInfo();
      state = AuthState(
        status: AuthStatus.authenticated,
        email: info['email'],
        name: info['name'],
        role: info['role'],
        userId: info['userId'],
        patientId: info['patientId'],
        doctorId: info['doctorId'],
        gender: info['gender'],
      );
    } else {
      final msg = result['message'] ?? 'Erreur de connexion';
      // If user not verified, redirect to verify
      if (msg.contains('not verified')) {
        state = AuthState(
          status: AuthStatus.needsVerification,
          email: email,
          errorMessage: msg,
        );
      } else if (msg.contains('does not complete')) {
        // User registered but no patient/doctor profile
        // We need to log them in first to get tokens, but backend returns 403
        state = AuthState(
          status: AuthStatus.needsProfileSetup,
          email: email,
          errorMessage: msg,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: msg,
        );
      }
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _authService.signup(data);
    if (result['success'] == true) {
      state = AuthState(
        status: AuthStatus.needsVerification,
        email: data['email'] as String,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: result['message'] ?? 'Erreur lors de l\'inscription',
      );
    }
    return result;
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _authService.verifyCode(email, code);
    if (result['success'] == true) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } else {
      state = state.copyWith(
        status: AuthStatus.needsVerification,
        errorMessage: result['message'],
        email: email,
      );
    }
    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
