// lib/data/services/token_storage_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';

abstract class ITokenStorageService {
  Future<void> saveTokens(AuthTokens tokens);
  Future<AuthTokens?> getTokens();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<bool> hasValidTokens();
  Future<void> saveUserRole(String role);
  Future<String?> getUserRole();
  Future<void> saveUserEmail(String email);
  Future<String?> getUserEmail();
  Future<void> saveUserId(int userId);
  Future<int?> getUserId();
  Future<void> savePatientId(int patientId);
  Future<int?> getPatientId();
}

class TokenStorageService implements ITokenStorageService {
  final FlutterSecureStorage _storage;
  const TokenStorageService(this._storage);

  static const _androidOptions = AndroidOptions(encryptedSharedPreferences: true);
  static const _iosOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device);

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    try {
      await Future.wait([
        _storage.write(key: AppConstants.accessTokenKey,  value: tokens.accessToken,  aOptions: _androidOptions, iOptions: _iosOptions),
        _storage.write(key: AppConstants.refreshTokenKey, value: tokens.refreshToken, aOptions: _androidOptions, iOptions: _iosOptions),
      ]);
    } catch (e, st) { AppLogger.e('Failed to save tokens', e, st); rethrow; }
  }

  @override
  Future<AuthTokens?> getTokens() async {
    try {
      final results = await Future.wait([
        _storage.read(key: AppConstants.accessTokenKey,  aOptions: _androidOptions, iOptions: _iosOptions),
        _storage.read(key: AppConstants.refreshTokenKey, aOptions: _androidOptions, iOptions: _iosOptions),
      ]);
      if (results[0] == null || results[1] == null) return null;
      return AuthTokens(accessToken: results[0]!, refreshToken: results[1]!);
    } catch (e, st) { AppLogger.e('Failed to read tokens', e, st); return null; }
  }

  @override
  Future<String?> getAccessToken() async {
    try { return await _storage.read(key: AppConstants.accessTokenKey, aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to read access token', e, st); return null; }
  }

  @override
  Future<String?> getRefreshToken() async {
    try { return await _storage.read(key: AppConstants.refreshTokenKey, aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to read refresh token', e, st); return null; }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: AppConstants.accessTokenKey,  aOptions: _androidOptions, iOptions: _iosOptions),
        _storage.delete(key: AppConstants.refreshTokenKey, aOptions: _androidOptions, iOptions: _iosOptions),
        _storage.delete(key: AppConstants.userRoleKey,     aOptions: _androidOptions, iOptions: _iosOptions),
        _storage.delete(key: AppConstants.userEmailKey,    aOptions: _androidOptions, iOptions: _iosOptions),
        _storage.delete(key: AppConstants.userIdKey,       aOptions: _androidOptions, iOptions: _iosOptions),
        _storage.delete(key: AppConstants.patientIdKey,    aOptions: _androidOptions, iOptions: _iosOptions),
      ]);
    } catch (e, st) { AppLogger.e('Failed to clear tokens', e, st); rethrow; }
  }

  @override
  Future<bool> hasValidTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveUserRole(String role) async {
    try { await _storage.write(key: AppConstants.userRoleKey, value: role, aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to save role', e, st); }
  }

  @override
  Future<String?> getUserRole() async {
    try { return await _storage.read(key: AppConstants.userRoleKey, aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to read role', e, st); return null; }
  }

  @override
  Future<void> saveUserEmail(String email) async {
    try { await _storage.write(key: AppConstants.userEmailKey, value: email, aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to save email', e, st); }
  }

  @override
  Future<String?> getUserEmail() async {
    try { return await _storage.read(key: AppConstants.userEmailKey, aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to read email', e, st); return null; }
  }

  @override
  Future<void> saveUserId(int userId) async {
    try { await _storage.write(key: AppConstants.userIdKey, value: userId.toString(), aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to save userId', e, st); }
  }

  @override
  Future<int?> getUserId() async {
    try {
      final v = await _storage.read(key: AppConstants.userIdKey, aOptions: _androidOptions, iOptions: _iosOptions);
      return v != null ? int.tryParse(v) : null;
    } catch (e, st) { AppLogger.e('Failed to read userId', e, st); return null; }
  }

  @override
  Future<void> savePatientId(int patientId) async {
    try { await _storage.write(key: AppConstants.patientIdKey, value: patientId.toString(), aOptions: _androidOptions, iOptions: _iosOptions); }
    catch (e, st) { AppLogger.e('Failed to save patientId', e, st); }
  }

  @override
  Future<int?> getPatientId() async {
    try {
      final v = await _storage.read(key: AppConstants.patientIdKey, aOptions: _androidOptions, iOptions: _iosOptions);
      return v != null ? int.tryParse(v) : null;
    } catch (e, st) { AppLogger.e('Failed to read patientId', e, st); return null; }
  }
}

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage());

final tokenStorageServiceProvider = Provider<ITokenStorageService>((ref) {
  return TokenStorageService(ref.watch(flutterSecureStorageProvider));
});
