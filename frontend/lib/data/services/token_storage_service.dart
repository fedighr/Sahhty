// lib/data/services/token_storage_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';

/// Abstract interface for testability and future swapping
abstract class ITokenStorageService {
  Future<void> saveTokens(AuthTokens tokens);
  Future<AuthTokens?> getTokens();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<bool> hasValidTokens();
}

class TokenStorageService implements ITokenStorageService {
  final FlutterSecureStorage _storage;

  const TokenStorageService(this._storage);

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    try {
      await Future.wait([
        _storage.write(
          key: AppConstants.accessTokenKey,
          value: tokens.accessToken,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        ),
        _storage.write(
          key: AppConstants.refreshTokenKey,
          value: tokens.refreshToken,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        ),
      ]);
      AppLogger.d('Tokens saved securely');
    } catch (e, st) {
      AppLogger.e('Failed to save tokens', e, st);
      rethrow;
    }
  }

  @override
  Future<AuthTokens?> getTokens() async {
    try {
      final results = await Future.wait([
        _storage.read(
          key: AppConstants.accessTokenKey,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        ),
        _storage.read(
          key: AppConstants.refreshTokenKey,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        ),
      ]);

      final accessToken = results[0];
      final refreshToken = results[1];

      if (accessToken == null || refreshToken == null) return null;

      return AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e, st) {
      AppLogger.e('Failed to read tokens', e, st);
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(
        key: AppConstants.accessTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, st) {
      AppLogger.e('Failed to read access token', e, st);
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(
        key: AppConstants.refreshTokenKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } catch (e, st) {
      AppLogger.e('Failed to read refresh token', e, st);
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(
          key: AppConstants.accessTokenKey,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        ),
        _storage.delete(
          key: AppConstants.refreshTokenKey,
          aOptions: _androidOptions,
          iOptions: _iosOptions,
        ),
      ]);
      AppLogger.d('Tokens cleared');
    } catch (e, st) {
      AppLogger.e('Failed to clear tokens', e, st);
      rethrow;
    }
  }

  @override
  Future<bool> hasValidTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageServiceProvider = Provider<ITokenStorageService>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return TokenStorageService(storage);
});
