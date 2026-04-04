import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/alert_model.dart';
import 'dio_client.dart';

class AlertService {
  final Dio _dio;
  const AlertService(this._dio);

  /// GET /alerts/AlertService/{userId}/get_alerts_by_user/
  Future<List<Alert>> getAlerts(int userId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.alertsByUser}$userId/get_alerts_by_user/',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // Backend may wrap: { success: true, alerts: [...] }
          if (data['alerts'] is List) {
            return (data['alerts'] as List)
                .map((e) => Alert.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          if (data['data'] is List) {
            return (data['data'] as List)
                .map((e) => Alert.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
        if (data is List) {
          return data
              .map((e) => Alert.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.e('Alerts list failed', e);
      return [];
    }
  }

  Future<List<Alert>> getUnreadAlerts(int userId) async {
    final all = await getAlerts(userId);
    return all.where((a) => a.isNew).toList();
  }

  /// PATCH /alerts/AlertService/{alertId}/mark_as_read/
  Future<void> markAsRead(int alertId) async {
    try {
      await _dio.patch('${AppConstants.alertMarkRead}$alertId/mark_as_read/');
    } catch (e) {
      AppLogger.w('Mark alert as read failed');
    }
  }
}

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService(ref.watch(protectedDioProvider));
});
