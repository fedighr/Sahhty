// lib/features/auth/providers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_failure.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final IAuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.watch(authRepositoryProvider);
    _checkExistingSession();
    return const AuthInitial();
  }

  Future<void> _checkExistingSession() async {
    try {
      final isAuth = await _repo.isAuthenticated();
      if (isAuth) {
        final tokens = await _repo.getCachedTokens();
        final role   = await _repo.getCachedRole();
        if (tokens != null) {
          AppLogger.i('Session restored — role: $role');
          state = AuthAuthenticated(tokens: tokens, role: role);
          return;
        }
      }
      state = const AuthUnauthenticated();
    } catch (e, st) {
      AppLogger.e('Session check failed', e, st);
      state = const AuthUnauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    try {
      final result = await _repo.signIn(SignInRequest(email: email, password: password));
      state = AuthAuthenticated(tokens: result.tokens, role: result.role);
    } on AuthFailure catch (e) {
      state = AuthError(message: e.message, statusCode: e.statusCode);
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'Erreur inattendue. Réessayez.');
    }
  }

  Future<void> signUp({
    required String firstName, required String lastName,
    required String email, required String phone,
    required String password, required String birthDate,
    required String gender, required String role,
  }) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    try {
      await _repo.signUp(SignUpRequest(
        firstName: firstName, lastName: lastName, email: email,
        phone: phone, password: password, birthDate: birthDate,
        gender: gender, role: role,
      ));
      state = AuthAwaitingVerification(email: email);
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'Erreur inattendue. Réessayez.');
    }
  }

  Future<void> verifyCode({required String email, required String code}) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    try {
      await _repo.verifyCode(VerifyCodeRequest(email: email, code: code));
      // After OTP verification user still needs to set up profile
      // Restore the role that was saved during signUp
      final role = await _repo.getCachedRole();
      state = AuthVerified(email: email, role: role);
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'Erreur inattendue. Réessayez.');
    }
  }

  Future<void> resendCode({required String email}) async {
    try {
      await _repo.resendCode(EmailRequest(email: email));
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {}
  }

  Future<void> startPasswordReset({required String email}) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    try {
      await _repo.verifyResetEmail(EmailRequest(email: email));
      state = AuthAwaitingResetCode(email: email);
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'Erreur inattendue. Réessayez.');
    }
  }

  Future<void> verifyResetCode({required String email, required String code}) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    try {
      await _repo.verifyResetCode(VerifyCodeRequest(email: email, code: code));
      state = AuthCanResetPassword(email: email);
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'Erreur inattendue. Réessayez.');
    }
  }

  Future<void> resetPassword({required String email, required String newPassword}) async {
    if (state is AuthLoading) return;
    state = const AuthLoading();
    try {
      await _repo.forgotPassword(ForgotPasswordRequest(email: email, password: newPassword));
      state = const AuthPasswordReset();
    } on AppFailure catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'Erreur inattendue. Réessayez.');
    }
  }

  Future<void> signOut() async {
    try { await _repo.signOut(); }
    finally { state = const AuthUnauthenticated(); }
  }

  void resetError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }

  void goBackToLogin() => state = const AuthUnauthenticated();
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
