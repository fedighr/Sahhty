import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

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
            // Retry the original request
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
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {'Content-Type': 'application/json'},
      )).post(ApiEndpoints.refreshToken, data: {'refresh': refreshToken});

      if (response.statusCode == 200 && response.data['access'] != null) {
        await _storage.write(
          key: StorageKeys.accessToken,
          value: response.data['access'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
