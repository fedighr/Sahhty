// lib/data/repositories/auth_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../services/token_storage_service.dart';

abstract class IAuthRepository {
  Future<AuthTokensWithRole> signIn(SignInRequest request);
  Future<void> signUp(SignUpRequest request);
  Future<void> verifyCode(VerifyCodeRequest request);
  Future<void> resendCode(EmailRequest request);
  Future<void> verifyResetEmail(EmailRequest request);
  Future<void> verifyResetCode(VerifyCodeRequest request);
  Future<void> forgotPassword(ForgotPasswordRequest request);
  Future<void> signOut();
  Future<bool> isAuthenticated();
  Future<AuthTokens?> getCachedTokens();
  Future<String> getCachedRole();
  Future<int?> getCachedUserId();
  Future<int?> getCachedPatientId();
  Future<void> savePatientId(int patientId);
}

/// Wraps tokens + role returned from signIn
class AuthTokensWithRole {
  final AuthTokens tokens;
  final String role;
  final int? userId;
  final String? name;
  const AuthTokensWithRole({required this.tokens, required this.role, this.userId, this.name});
}

class AuthRepository implements IAuthRepository {
  final IAuthService _authService;
  final ITokenStorageService _tokenStorage;

  const AuthRepository({
    required IAuthService authService,
    required ITokenStorageService tokenStorage,
  })  : _authService = authService,
        _tokenStorage = tokenStorage;

  @override
  Future<AuthTokensWithRole> signIn(SignInRequest request) async {
    try {
      final result = await _authService.signIn(request);
      await _tokenStorage.saveTokens(result.tokens);
      // Save role and email for later use (profile setup, routing)
      await _tokenStorage.saveUserRole(result.role);
      await _tokenStorage.saveUserEmail(request.email.trim().toLowerCase());
      // Save userId extracted from JWT
      if (result.userId != null) {
        await _tokenStorage.saveUserId(result.userId!);
      }
      // Save display name from JWT
      if (result.name != null && result.name!.isNotEmpty) {
        await _tokenStorage.saveUserDisplayName(result.name!);
      }
      AppLogger.i('SignIn successful — role: ${result.role}, userId: ${result.userId}');
      return result;
    } on AppFailure { rethrow; }
    catch (e, st) {
      AppLogger.e('Repository signIn error', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> signUp(SignUpRequest request) async {
    try {
      await _authService.signUp(request);
      // Save role and email so profile setup screen can use them
      await _tokenStorage.saveUserRole(request.role);
      await _tokenStorage.saveUserEmail(request.email.trim().toLowerCase());
    } on AppFailure { rethrow; }
    catch (e, st) {
      AppLogger.e('Repository signUp error', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> verifyCode(VerifyCodeRequest request) async {
    try { await _authService.verifyCode(request); }
    on AppFailure { rethrow; }
    catch (e, st) { AppLogger.e('Repository verifyCode error', e, st); throw const UnexpectedFailure(); }
  }

  @override
  Future<void> resendCode(EmailRequest request) async {
    try { await _authService.resendCode(request); }
    on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> verifyResetEmail(EmailRequest request) async {
    try { await _authService.verifyResetEmail(request); }
    on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> verifyResetCode(VerifyCodeRequest request) async {
    try { await _authService.verifyResetCode(request); }
    on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try { await _authService.forgotPassword(request); }
    on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> signOut() async {
    try { await _tokenStorage.clearTokens(); }
    catch (e, st) {
      AppLogger.e('Repository signOut error', e, st);
      throw const StorageFailure();
    }
  }

  @override
  Future<bool> isAuthenticated() => _tokenStorage.hasValidTokens();

  @override
  Future<AuthTokens?> getCachedTokens() => _tokenStorage.getTokens();

  @override
  Future<String> getCachedRole() async {
    final role = await _tokenStorage.getUserRole();
    return role ?? 'P'; // default to patient if unknown
  }

  @override
  Future<int?> getCachedUserId() => _tokenStorage.getUserId();

  @override
  Future<int?> getCachedPatientId() => _tokenStorage.getPatientId();

  @override
  Future<void> savePatientId(int patientId) => _tokenStorage.savePatientId(patientId);
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  );
});
