// lib/data/repositories/auth_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../services/token_storage_service.dart';

abstract class IAuthRepository {
  Future<AuthTokens> signIn(SignInRequest request);
  Future<void> signUp(SignUpRequest request);
  Future<void> verifyCode(VerifyCodeRequest request);
  Future<void> resendCode(EmailRequest request);
  Future<void> verifyResetEmail(EmailRequest request);
  Future<void> verifyResetCode(VerifyCodeRequest request);
  Future<void> forgotPassword(ForgotPasswordRequest request);
  Future<void> signOut();
  Future<bool> isAuthenticated();
  Future<AuthTokens?> getCachedTokens();
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
  Future<AuthTokens> signIn(SignInRequest request) async {
    try {
      final tokens = await _authService.signIn(request);
      await _tokenStorage.saveTokens(tokens);
      return tokens;
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
    } on AppFailure { rethrow; }
    catch (e, st) {
      AppLogger.e('Repository signUp error', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> verifyCode(VerifyCodeRequest request) async {
    try {
      await _authService.verifyCode(request);
    } on AppFailure { rethrow; }
    catch (e, st) {
      AppLogger.e('Repository verifyCode error', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> resendCode(EmailRequest request) async {
    try {
      await _authService.resendCode(request);
    } on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> verifyResetEmail(EmailRequest request) async {
    try {
      await _authService.verifyResetEmail(request);
    } on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> verifyResetCode(VerifyCodeRequest request) async {
    try {
      await _authService.verifyResetCode(request);
    } on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      await _authService.forgotPassword(request);
    } on AppFailure { rethrow; }
    catch (_) { throw const UnexpectedFailure(); }
  }

  @override
  Future<void> signOut() async {
    try {
      await _tokenStorage.clearTokens();
    } catch (e, st) {
      AppLogger.e('Repository signOut error', e, st);
      throw const StorageFailure();
    }
  }

  @override
  Future<bool> isAuthenticated() => _tokenStorage.hasValidTokens();

  @override
  Future<AuthTokens?> getCachedTokens() => _tokenStorage.getTokens();
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  );
});
