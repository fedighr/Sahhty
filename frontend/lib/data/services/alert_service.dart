import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

class AlertService {
  final Dio _dio = DioClient().dio;

  /// GET /alerts/AlertService/{userId}/get_alerts_by_user/?page=N
  /// Backend returns DRF paginated: {count, next, previous, results: [...]}
  Future<Map<String, dynamic>> getAlertsByUser(int userId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getAlertsByUser(userId),
        queryParameters: {'page': page},
      );
      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        return {
          'success': true,
          'alerts': data['results'],
          'count': data['count'] ?? 0,
          'next': data['next'],
          'previous': data['previous'],
        };
      }
      return data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// PATCH /alerts/AlertService/{alertId}/mark_as_read/
  Future<Map<String, dynamic>> markAsRead(int alertId) async {
    try {
      final response = await _dio.patch(ApiEndpoints.markAlertAsRead(alertId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  Map<String, dynamic> _err(DioException e) {
    if (e.response?.data is Map<String, dynamic>) return e.response!.data;
    return {'success': false, 'message': e.message ?? 'Erreur réseau'};
  }
}
