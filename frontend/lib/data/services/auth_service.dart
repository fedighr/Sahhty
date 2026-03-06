// lib/data/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';
import 'dio_client.dart';

abstract class IAuthService {
  Future<AuthTokens> signIn(SignInRequest request);
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
  Future<AuthTokens> signIn(SignInRequest request) async {
    try {
      AppLogger.i('SignIn: \${request.email}');
      final response = await _dio.post(AppConstants.signinEndpoint, data: request.toJson());
      return _parseTokens(response);
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
    } on DioException catch (e, st) {
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> resendCode(EmailRequest request) async {
    try {
      final response = await _dio.post(AppConstants.resendCodeEndpoint, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) {
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> verifyResetEmail(EmailRequest request) async {
    try {
      final response = await _dio.post(AppConstants.verifyResetEmail, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) {
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> verifyResetCode(VerifyCodeRequest request) async {
    try {
      final response = await _dio.post(AppConstants.verifyResetCode, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) {
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(AppConstants.forgetPassword, data: request.toJson());
      _assertSuccess(response);
    } on DioException catch (e, st) {
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      throw const UnexpectedFailure();
    }
  }

  AuthTokens _parseTokens(Response response) {
    final statusCode = response.statusCode ?? 0;
    final body = response.data as Map<String, dynamic>?;
    if (body == null) throw const ServerFailure(message: 'Réponse vide.');
    final success = body['success'] as bool? ?? false;
    if (!success || statusCode >= 400) {
      final msg = body['message'] as String? ?? 'Erreur d\'authentification.';
      if (statusCode == 403) throw AuthFailure(message: msg, statusCode: 403);
      throw ServerFailure(message: msg, statusCode: statusCode);
    }
    try {
      return AuthTokens(
        accessToken: body['access'] as String,
        refreshToken: body['refresh'] as String,
      );
    } catch (_) {
      throw const ServerFailure(message: 'Tokens manquants dans la réponse.');
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
