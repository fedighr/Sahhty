import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

/// Handles login/signup/verify — never uses auth token on its own requests.
class AuthService {
  final Dio _dio = DioClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Sign Up ──────────────────────────────────────────────────────────
  /// Backend expects ALL User model fields: first_name, last_name, birth_date,
  /// email, phone, gender, role, password
  Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.signup, data: data);
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Sign In ──────────────────────────────────────────────────────────
  /// Backend expects {email, password}. Returns {success, access, refresh}
  Future<Map<String, dynamic>> signin(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.signin,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['access'] != null) {
        await _saveTokens(data['access'], data['refresh']);
      }
      return data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Verify Code (after signup) ───────────────────────────────────────
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyCode,
        data: {'email': email, 'code': code},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Resend Code ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resendCode(String email) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.resendCode,
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Verify Reset Email (forgot password step 1) ─────────────────────
  Future<Map<String, dynamic>> verifyResetEmail(String email) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyResetEmail,
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Verify Reset Code (forgot password step 2) ──────────────────────
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyResetCode,
        data: {'email': email, 'code': code},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  

  // ── Forget Password (forgot password step 3) ────────────────────────
  Future<Map<String, dynamic>> forgetPassword(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.forgetPassword,
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Token decode helpers ─────────────────────────────────────────────
  /// JWT payload decode (the backend puts user info inside the access token)
  Map<String, dynamic> decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  /// Save tokens + decoded user info to secure storage
  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: StorageKeys.accessToken, value: access);
    await _storage.write(key: StorageKeys.refreshToken, value: refresh);

    final payload = decodeJwtPayload(access);
    if (payload.isNotEmpty) {
      await _storage.write(key: StorageKeys.userEmail, value: payload['email'] ?? '');
      await _storage.write(key: StorageKeys.userName, value: payload['name'] ?? '');
      await _storage.write(key: StorageKeys.userRole, value: payload['role'] ?? '');
      await _storage.write(key: StorageKeys.userId, value: '${payload['user_id'] ?? ''}');
      await _storage.write(key: StorageKeys.userGender, value: payload['gender'] ?? '');
      if (payload['patient_id'] != null) {
        await _storage.write(key: StorageKeys.patientId, value: '${payload['patient_id']}');
      }
      if (payload['doctor_id'] != null) {
        await _storage.write(key: StorageKeys.doctorId, value: '${payload['doctor_id']}');
      }
    }
  }

  // ── FCM Device Registration ──────────────────────────────────────────
  /// Must be called AFTER login (requires auth token)
  Future<Map<String, dynamic>> registerFcmDevice(String fcmToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerDevice,
        data: {'fcm_token': fcmToken},
      );
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Delete Account ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> deleteAccount(int userId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.deleteAccount(userId));
      return response.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // ── Check if logged in ──────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  // ── Get stored user info ────────────────────────────────────────────
  Future<Map<String, String?>> getStoredUserInfo() async {
    return {
      'email': await _storage.read(key: StorageKeys.userEmail),
      'name': await _storage.read(key: StorageKeys.userName),
      'role': await _storage.read(key: StorageKeys.userRole),
      'userId': await _storage.read(key: StorageKeys.userId),
      'patientId': await _storage.read(key: StorageKeys.patientId),
      'doctorId': await _storage.read(key: StorageKeys.doctorId),
      'gender': await _storage.read(key: StorageKeys.userGender),
    };
  }

  // ── Error handler ───────────────────────────────────────────────────
  Map<String, dynamic> _handleError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response!.data as Map<String, dynamic>;
    }
    return {
      'success': false,
      'message': e.message ?? 'Une erreur réseau est survenue',
    };
  }
}
