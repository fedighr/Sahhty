// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Sahhty';
  static const String appVersion = '1.0.0';

  // Base URL — change to your Django backend
  static const String baseUrl = 'http://192.168.1.106:8000';

  // API Endpoints
  static const String signupEndpoint = '/users/auth/signup/';
  static const String signinEndpoint = '/users/auth/signin/';
  static const String refreshEndpoint = '/users/auth/refresh/';

  // Secure Storage Keys
  static const String accessTokenKey = 'sahhty_access_token';
  static const String refreshTokenKey = 'sahhty_refresh_token';
  static const String userDataKey = 'sahhty_user_data';

  // Timeouts (milliseconds)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Validation
  static const int passwordMinLength = 8;
  static const int phoneLength = 8;

  // HTTP Headers
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  static const String contentTypeHeader = 'Content-Type';
  static const String applicationJson = 'application/json';
}
