// lib/features/auth/providers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_failure.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final IAuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    // Check persisted session on startup
    _checkExistingSession();
    return const AuthInitial();
  }

  /// Called on app start — restores session from secure storage
  Future<void> _checkExistingSession() async {
    try {
      final isAuth = await _repository.isAuthenticated();
      if (isAuth) {
        final tokens = await _repository.getCachedTokens();
        if (tokens != null) {
          AppLogger.i('Existing session found — restoring auth state');
          state = AuthAuthenticated(tokens: tokens);
          return;
        }
      }
      state = const AuthUnauthenticated();
    } catch (e, st) {
      AppLogger.e('Session check failed', e, st);
      state = const AuthUnauthenticated();
    }
  }

  /// Sign In
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (state is AuthLoading) return;

    state = const AuthLoading();

    try {
      final tokens = await _repository.signIn(
        SignInRequest(email: email, password: password),
      );
      AppLogger.i('AuthNotifier: signIn success');
      state = AuthAuthenticated(tokens: tokens);
    } on AuthFailure catch (e) {
      AppLogger.w('AuthNotifier: auth failure — ${e.message}');
      state = AuthError(message: e.message, statusCode: e.statusCode);
    } on ValidationFailure catch (e) {
      AppLogger.w('AuthNotifier: validation failure — ${e.message}');
      state = AuthError(message: e.message, statusCode: e.statusCode);
    } on NetworkFailure catch (e) {
      AppLogger.w('AuthNotifier: network failure — ${e.message}');
      state = AuthError(message: e.message);
    } on ServerFailure catch (e) {
      AppLogger.w('AuthNotifier: server failure — ${e.message}');
      state = AuthError(message: e.message, statusCode: e.statusCode);
    } on AppFailure catch (e) {
      AppLogger.e('AuthNotifier: unexpected failure — ${e.message}');
      state = AuthError(message: e.message);
    } catch (e, st) {
      AppLogger.e('AuthNotifier: unknown error', e, st);
      state = const AuthError(
        message: 'Erreur inattendue. Réessayez.',
      );
    }
  }

  /// Sign Up
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String birthDate,
    required String gender,
    required String role,
  }) async {
    if (state is AuthLoading) return;

    state = const AuthLoading();

    try {
      final tokens = await _repository.signUp(
        SignUpRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          password: password,
          confirmPassword: confirmPassword,
          birthDate: birthDate,
          gender: gender,
          role: role,
        ),
      );
      AppLogger.i('AuthNotifier: signUp success');
      state = AuthAuthenticated(tokens: tokens);
    } on AuthFailure catch (e) {
      state = AuthError(message: e.message, statusCode: e.statusCode);
    } on ValidationFailure catch (e) {
      state = AuthError(message: e.message, statusCode: e.statusCode);
    } on NetworkFailure catch (e) {
      state = AuthError(message: e.message);
    } on ServerFailure catch (e) {
      state = AuthError(message: e.message, statusCode: e.statusCode);
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (e, st) {
      AppLogger.e('AuthNotifier: signUp unknown error', e, st);
      state = const AuthError(
        message: 'Erreur inattendue. Réessayez.',
      );
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _repository.signOut();
      state = const AuthUnauthenticated();
      AppLogger.i('AuthNotifier: signed out');
    } catch (e, st) {
      AppLogger.e('AuthNotifier: signOut error', e, st);
      // Force logout even if storage fails
      state = const AuthUnauthenticated();
    }
  }

  /// Reset error state (e.g., when navigating back)
  void resetError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
