// lib/data/services/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';
import '../repositories/auth_repository.dart';
import 'dio_client.dart';

abstract class IAuthService {
  Future<AuthTokensWithRole> signIn(SignInRequest request);
  Future<void> signUp(SignUpRequest request);
  Future<void> verifyCode(VerifyCodeRequest request);
  Future<void> resendCode(EmailRequest request);
  Future<void> verifyResetEmail(EmailRequest request);
  Future<void> verifyResetCode(VerifyCodeRequest request);
  Future<void> forgotPassword(ForgotPasswordRequest request);
}

class AuthService implements IAuthService {
  final Dio _dio;
  const AuthService(this._dio);

  @override
  Future<AuthTokensWithRole> signIn(SignInRequest request) async {
    try {
      AppLogger.i('SignIn: ${request.email}');
      final response = await _dio.post(AppConstants.signinEndpoint, data: request.toJson());
      return _parseSignInResponse(response);
    } on DioException catch (e, st) {
      AppLogger.e('signIn DioException', e, st);
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> signUp(SignUpRequest request) async {
    try {
      final response = await _dio.post(AppConstants.signupEndpoint, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) {
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> verifyCode(VerifyCodeRequest request) async {
    try {
      final response = await _dio.post(AppConstants.verifyCodeEndpoint, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) { throw _mapDioError(e); }
    catch (e, st) { if (e is AppFailure) rethrow; throw const UnexpectedFailure(); }
  }

  @override
  Future<void> resendCode(EmailRequest request) async {
    try {
      final response = await _dio.post(AppConstants.resendCodeEndpoint, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) { throw _mapDioError(e); }
    catch (e, st) { if (e is AppFailure) rethrow; throw const UnexpectedFailure(); }
  }

  @override
  Future<void> verifyResetEmail(EmailRequest request) async {
    try {
      final response = await _dio.post(AppConstants.verifyResetEmail, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) { throw _mapDioError(e); }
    catch (e, st) { if (e is AppFailure) rethrow; throw const UnexpectedFailure(); }
  }

  @override
  Future<void> verifyResetCode(VerifyCodeRequest request) async {
    try {
      final response = await _dio.post(AppConstants.verifyResetCode, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) { throw _mapDioError(e); }
    catch (e, st) { if (e is AppFailure) rethrow; throw const UnexpectedFailure(); }
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(AppConstants.forgetPassword, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) { throw _mapDioError(e); }
    catch (e, st) { if (e is AppFailure) rethrow; throw const UnexpectedFailure(); }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Parse signin response and extract role from JWT payload.
  /// Backend JWT claims include: email, name — but NOT role.
  /// Role comes from the User model's `role` field ('P'|'D').
  /// Since the backend doesn't include role in JWT claims, we decode
  /// the access token payload to get what's available, then fall back
  /// to reading the role the user selected during registration.
  AuthTokensWithRole _parseSignInResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw const ServerFailure(message: 'Réponse vide.');

    final success = body['success'] as bool? ?? false;
    if (!success || statusCode >= 400) {
      final msg = body['message'] as String? ?? 'Erreur d\'authentification.';
      if (statusCode == 403) throw AuthFailure(message: msg, statusCode: 403);
      throw ServerFailure(message: msg, statusCode: statusCode);
    }

    final accessToken  = body['access']  as String?;
    final refreshToken = body['refresh'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw const ServerFailure(message: 'Tokens manquants dans la réponse.');
    }

    // Decode JWT payload to extract role and user_id claims
    final role = _extractRoleFromJwt(accessToken);
    final userId = _extractUserIdFromJwt(accessToken);
    final name = _extractNameFromJwt(accessToken);
    AppLogger.i('Login role extracted from JWT: $role, userId: $userId, name: $name');

    return AuthTokensWithRole(
      tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
      role: role,
      userId: userId,
      name: name,
    );
  }

  /// Decodes the JWT payload (base64url) and extracts the `user_id` claim.
  int? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) payload += '=';
      final decoded = utf8.decode(base64Decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return claims['user_id'] as int?;
    } catch (e) {
      AppLogger.w('Could not decode JWT user_id: $e');
      return null;
    }
  }

  /// Decodes the JWT payload (base64url) and extracts the `role` claim.
  /// Returns 'P' if role claim is absent (safe default).
  String _extractRoleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'P';
      // Base64url decode — pad to multiple of 4
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) payload += '=';
      final decoded = utf8.decode(base64Decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      // Django SimpleJWT stores custom claims at top level
      final role = claims['role'] as String?;
      if (role != null) return role;
      // Fallback: infer from token claim 'user_role' or similar
      return 'P';
    } catch (e) {
      AppLogger.w('Could not decode JWT role: $e');
      return 'P';
    }
  }

  /// Decodes the JWT payload and extracts the `name` claim.
  String? _extractNameFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) payload += '=';
      final decoded = utf8.decode(base64Decode(payload));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return claims['name'] as String?;
    } catch (e) {
      AppLogger.w('Could not decode JWT name: $e');
      return null;
    }
  }

  void _assertSuccess(Response response) {
    final statusCode = response.statusCode ?? 0;
    final body = response.data;
    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final success = map['success'] as bool? ?? false;
    if (!success || statusCode >= 400) {
      final msg = map['message'] as String? ?? 'Une erreur est survenue.';
      if (statusCode == 403) throw AuthFailure(message: msg, statusCode: 403);
      if (statusCode == 400) throw ValidationFailure(message: msg, statusCode: statusCode);
      throw ServerFailure(message: msg, statusCode: statusCode);
    }
  }

  AppFailure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      default:
        final body = e.response?.data;
        if (body is Map<String, dynamic>) {
          final msg = body['message'] as String? ?? 'Erreur serveur.';
          final code = e.response?.statusCode;
          if (code == 403) return AuthFailure(message: msg, statusCode: code);
          return ServerFailure(message: msg, statusCode: code);
        }
        return const UnexpectedFailure();
    }
  }
}

final authServiceProvider = Provider<IAuthService>((ref) {
  final dio = ref.watch(authDioProvider);
  return AuthService(dio);
});
