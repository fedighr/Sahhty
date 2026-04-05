import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

class AlertService {
  final Dio _dio = DioClient().dio;

  /// GET /alerts/AlertService/{userId}/get_alerts_by_user/
  /// Returns: {success, alerts: [{id, type, message, level, status, created_at, user: {...}}]}
  Future<Map<String, dynamic>> getAlertsByUser(int userId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getAlertsByUser(userId));
      return response.data;
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
