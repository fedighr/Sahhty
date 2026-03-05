// lib/data/services/dio_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import 'auth_interceptor.dart';
import 'token_storage_service.dart';

/// Creates and configures the Dio HTTP client.
/// Separate instances: one for auth endpoints, one for protected endpoints.
class DioClient {
  DioClient._();

  static Dio createAuthDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          'Accept': AppConstants.applicationJson,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (const bool.fromEnvironment('dart.vm.product') == false) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (log) => AppLogger.d(log),
        ),
      );
    }

    return dio;
  }

  static Dio createProtectedDio(ITokenStorageService tokenStorage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          'Accept': AppConstants.applicationJson,
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Inject auth interceptor
    dio.interceptors.add(
      AuthInterceptor(tokenStorage: tokenStorage, dio: dio),
    );

    if (const bool.fromEnvironment('dart.vm.product') == false) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (log) => AppLogger.d(log),
        ),
      );
    }

    return dio;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// Unauthenticated Dio — used only for login/signup
final authDioProvider = Provider<Dio>((ref) {
  return DioClient.createAuthDio();
});

/// Authenticated Dio — used for all protected endpoints
final protectedDioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  return DioClient.createProtectedDio(tokenStorage);
});
