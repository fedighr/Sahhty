import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/alert_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';

class AlertService {
  final Dio _dio;
  const AlertService(this._dio);

  Future<List<Alert>> getAlerts() async {
    try {
      final response = await _dio.get(AppConstants.alertsList);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Alert.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load alerts');
    } catch (e) {
      AppLogger.w('Alerts list endpoint not available, using mock data');
      return MockData.alerts;
    }
  }

  Future<List<Alert>> getUnreadAlerts() async {
    final all = await getAlerts();
    return all.where((a) => a.isNew).toList();
  }

  Future<void> markAsRead(int alertId) async {
    try {
      await _dio.patch('${AppConstants.alertMarkRead}$alertId/');
    } catch (e) {
      AppLogger.w('Mark alert as read endpoint not available');
    }
  }
}

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService(ref.watch(protectedDioProvider));
});
