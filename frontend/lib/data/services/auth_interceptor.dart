// lib/data/services/auth_interceptor.dart

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import 'token_storage_service.dart';

/// Interceptor that:
/// 1. Attaches access token to every request
/// 2. Handles 401 → prepared for token refresh logic
/// 3. Clears tokens on auth failure
class AuthInterceptor extends Interceptor {
  final ITokenStorageService _tokenStorage;
  final Dio _dio;

  // Flag to prevent infinite refresh loops
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor({
    required ITokenStorageService tokenStorage,
    required Dio dio,
  })  : _tokenStorage = tokenStorage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth endpoints — they don't need tokens
    final isAuthEndpoint = options.path.contains('/auth/signin') ||
        options.path.contains('/auth/signup');

    if (!isAuthEndpoint) {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers[AppConstants.authorizationHeader] =
            '${AppConstants.bearerPrefix}$accessToken';
        AppLogger.d('Token attached to request: ${options.path}');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d(
        'Response [${response.statusCode}] → ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    AppLogger.e(
      'DioError [${err.response?.statusCode}] → ${err.requestOptions.path}',
      err,
    );

    if (err.response?.statusCode == 401) {
      // ── Future: Implement token refresh here ──────────────────────────
      // 1. Check if we have a refresh token
      // 2. Call POST /users/auth/token/refresh
      // 3. Save new tokens
      // 4. Retry original request
      // 5. If refresh fails → logout
      //
      // Currently: just clear tokens (logout)
      AppLogger.w('401 received — clearing tokens (refresh not yet wired)');
      await _tokenStorage.clearTokens();
      // You can emit a logout event here using a stream or StateNotifier
    }

    handler.next(err);
  }
}
