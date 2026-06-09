import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  /// Émis quand le refresh token est expiré/invalide → l'app doit rediriger vers /login
  static final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  static Stream<void> get sessionExpiredStream =>
      _sessionExpiredController.stream;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: StorageKeys.accessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final token = await _storage.read(key: StorageKeys.accessToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
      // Pas de refresh token → l'utilisateur n'est pas connecté, rien à faire
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {'Content-Type': 'application/json'},
      )).post(ApiEndpoints.refreshToken, data: {'refresh': refreshToken});

      if (response.statusCode == 200 && response.data['access'] != null) {
        final newToken = response.data['access'] as String;

        await _storage.write(
          key: StorageKeys.accessToken,
          value: newToken,
        );

        try {
          const channel = MethodChannel('com.example.sahhty/wear');
          final patientId = await _storage.read(key: StorageKeys.patientId) ?? '';
          await channel.invokeMethod('setCredentials', {
            'token': newToken,
            'patient_id': patientId,
          });
          debugPrint('[DioClient] Native credentials updated after token refresh ✅');
        } catch (e) {
          debugPrint('[DioClient] Failed to update native credentials: $e');
        }

        return true;
      }

      // Réponse reçue mais pas 200 → token expiré ou invalide
      debugPrint('[DioClient] Refresh token rejeté (${response.statusCode}) → session expirée');
      await _onSessionExpired();
      return false;
    } on DioException catch (e) {
      // Le serveur a explicitement refusé le refresh token
      if (e.response != null &&
          (e.response!.statusCode == 401 || e.response!.statusCode == 403)) {
        debugPrint('[DioClient] Refresh token invalide (${e.response!.statusCode}) → session expirée');
        await _onSessionExpired();
      }
      // Erreur réseau (pas de réponse) → ne pas déconnecter, échec silencieux
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Efface tous les tokens et notifie l'application de rediriger vers /login
  Future<void> _onSessionExpired() async {
    await _storage.deleteAll();
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }
}