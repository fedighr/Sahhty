// lib/data/services/profile_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_failure.dart';
import '../../core/utils/app_logger.dart';
import '../models/auth_model.dart';
import 'dio_client.dart';

abstract class IProfileService {
  Future<void> createPatient(CreatePatientRequest request);
  Future<void> createDoctor(CreateDoctorRequest request);
}

class ProfileService implements IProfileService {
  final Dio _dio;
  const ProfileService(this._dio);

  @override
  Future<void> createPatient(CreatePatientRequest request) async {
    try {
      AppLogger.i('Creating patient profile for: ${request.email}');
      final response = await _dio.post(
        AppConstants.createPatientEndpoint,
        data: request.toJson(),
      );
      _handleResponse(response);
    } on DioException catch (e, st) {
      AppLogger.e('createPatient DioException', e, st);
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      AppLogger.e('createPatient unexpected', e, st);
      throw const UnexpectedFailure();
    }
  }

  @override
  Future<void> createDoctor(CreateDoctorRequest request) async {
    try {
      AppLogger.i('Creating doctor profile userId: ${request.userId}');
      final response = await _dio.post(
        AppConstants.createDoctorEndpoint,
        data: request.toJson(),
      );
      _handleResponse(response);
    } on DioException catch (e, st) {
      AppLogger.e('createDoctor DioException', e, st);
      throw _mapDioError(e);
    } catch (e, st) {
      if (e is AppFailure) rethrow;
      AppLogger.e('createDoctor unexpected', e, st);
      throw const UnexpectedFailure();
    }
  }

  void _handleResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final body = response.data;

    AppLogger.d('Profile response [$statusCode]: $body');

    if (body == null) {
      throw const ServerFailure(message: 'Réponse serveur vide.');
    }

    final Map<String, dynamic> bodyMap =
        body is Map<String, dynamic> ? body : {};

    final success = bodyMap['success'] as bool? ?? false;

    if (!success || statusCode >= 400) {
      final message = bodyMap['message'] as String? ??
          'Une erreur est survenue.';
      if (statusCode == 400 || statusCode == 422) {
        throw ValidationFailure(message: message, statusCode: statusCode);
      }
      throw ServerFailure(message: message, statusCode: statusCode);
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
          return ServerFailure(
              message: msg, statusCode: e.response?.statusCode);
        }
        return const UnexpectedFailure();
    }
  }
}

final profileServiceProvider = Provider<IProfileService>((ref) {
  final dio = ref.watch(authDioProvider);
  return ProfileService(dio);
});
