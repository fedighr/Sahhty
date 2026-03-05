// lib/data/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';
import 'dio_client.dart';

/// Abstract interface — allows mocking in tests
abstract class IAuthService {
  Future<AuthTokens> signIn(SignInRequest request);
  Future<AuthTokens> signUp(SignUpRequest request);
}

class AuthService implements IAuthService {
  final Dio _dio;

  const AuthService(this._dio);

  @override
  Future<AuthTokens> signIn(SignInRequest request) async {
    try {
      AppLogger.i('SignIn request for: ${request.email}');

      final response = await _dio.post(
        AppConstants.signinEndpoint,
        data: request.toJson(),
      );

      return _handleAuthResponse(response);
    } on DioException catch (e, st) {
      AppLogger.e('SignIn DioException', e, st);
      throw _mapDioError(e);
    } catch (e, st) {
      AppLogger.e('SignIn unexpected error', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<AuthTokens> signUp(SignUpRequest request) async {
    try {
      AppLogger.i('SignUp request for: ${request.email}');

      final response = await _dio.post(
        AppConstants.signupEndpoint,
        data: request.toJson(),
      );

      return _handleAuthResponse(response);
    } on DioException catch (e, st) {
      AppLogger.e('SignUp DioException', e, st);
      throw _mapDioError(e);
    } catch (e, st) {
      AppLogger.e('SignUp unexpected error', e, st);
      throw const UnexpectedFailure();
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  AuthTokens _handleAuthResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final body = response.data;

    AppLogger.d('Auth response [$statusCode]: $body');

    if (body == null) {
      throw const ServerFailure(
        message: 'Réponse serveur vide.',
        statusCode: 0,
      );
    }

    final Map<String, dynamic> bodyMap;
    if (body is Map<String, dynamic>) {
      bodyMap = body;
    } else {
      throw const ServerFailure(message: 'Format de réponse invalide.');
    }

    final dataField = bodyMap['data'] as Map<String, dynamic>?;
    final success = dataField?['success'] as bool? ?? false;

    if (!success || statusCode >= 400) {
      final message = dataField?['message'] as String? ??
          'Une erreur est survenue. Réessayez.';

      if (statusCode == 401 || statusCode == 403) {
        throw AuthFailure(message: message, statusCode: statusCode);
      }
      if (statusCode == 400 || statusCode == 422) {
        throw ValidationFailure(message: message, statusCode: statusCode);
      }
      throw ServerFailure(message: message, statusCode: statusCode);
    }

    // Parse tokens from successful response
    try {
      return AuthTokens.fromJson(bodyMap);
    } catch (e) {
      AppLogger.e('Token parsing failed', e);
      throw const ServerFailure(
        message: 'Impossible de lire les tokens d\'authentification.',
      );
    }
  }

  AppFailure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Délai de connexion dépassé. Vérifiez votre réseau.',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);
      case DioExceptionType.cancel:
        return const UnexpectedFailure(
          message: 'La requête a été annulée.',
        );
      default:
        return const UnexpectedFailure();
    }
  }

  AppFailure _handleBadResponse(Response? response) {
    if (response == null) return const UnexpectedFailure();

    final statusCode = response.statusCode ?? 0;
    final body = response.data;
    String message = 'Erreur serveur. Réessayez.';

    if (body is Map<String, dynamic>) {
      final dataField = body['data'] as Map<String, dynamic>?;
      message = dataField?['message'] as String? ?? message;
    }

    if (statusCode >= 500) {
      return ServerFailure(
        message: 'Erreur serveur interne. Réessayez plus tard.',
        statusCode: statusCode,
      );
    }

    return ServerFailure(message: message, statusCode: statusCode);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<IAuthService>((ref) {
  final dio = ref.watch(authDioProvider);
  return AuthService(dio);
});
