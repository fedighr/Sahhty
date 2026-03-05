// lib/data/repositories/auth_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../services/token_storage_service.dart';

/// Abstract contract for testability
abstract class IAuthRepository {
  Future<AuthTokens> signIn(SignInRequest request);
  Future<AuthTokens> signUp(SignUpRequest request);
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
      AppLogger.i('SignIn successful — tokens persisted');
      return tokens;
    } on AppFailure {
      rethrow; // Already mapped — just propagate
    } catch (e, st) {
      AppLogger.e('Repository signIn error', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<AuthTokens> signUp(SignUpRequest request) async {
    try {
      final tokens = await _authService.signUp(request);
      await _tokenStorage.saveTokens(tokens);
      AppLogger.i('SignUp successful — tokens persisted');
      return tokens;
    } on AppFailure {
      rethrow;
    } catch (e, st) {
      AppLogger.e('Repository signUp error', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _tokenStorage.clearTokens();
      AppLogger.i('User signed out — tokens cleared');
    } catch (e, st) {
      AppLogger.e('Repository signOut error', e, st);
      throw const StorageFailure();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasValidTokens();
  }

  @override
  Future<AuthTokens?> getCachedTokens() async {
    return await _tokenStorage.getTokens();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  return AuthRepository(
    authService: authService,
    tokenStorage: tokenStorage,
  );
});
