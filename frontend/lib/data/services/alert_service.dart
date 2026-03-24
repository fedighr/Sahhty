import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/alert_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import 'patient_service.dart';

class AlertService {
  final Dio _dio;
  final PatientService _patientService;
  const AlertService(this._dio, this._patientService);

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
      AppLogger.w('Primary alerts endpoint unavailable, trying fallback');
      try {
        final patient = await _patientService.getProfile();
        final userId = patient.userId;
        if (userId != null) {
          final response = await _dio.get(
              '${AppConstants.legacyAlertsBase}/$userId/get_alerts_by_user/');
          if (response.statusCode == 200 && response.data is List) {
            return (response.data as List)
                .map((e) => Alert.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {
        AppLogger.w('Legacy alerts endpoint unavailable, using mock data');
      }
      return MockData.alerts;
    }
  }

  Future<List<Alert>> getUnreadAlerts() async {
    final all = await getAlerts();
    return all.where((a) => a.isNew).toList();
  }

  Future<void> markAsRead(int alertId) async {
    try {
      final response = await _dio.patch(
          '${AppConstants.alertMarkRead}/$alertId/mark_read/');
      if (response.statusCode != null && response.statusCode! < 400) return;
      throw Exception('Failed to mark alert as read');
    } catch (e) {
      AppLogger.w('Primary mark-as-read endpoint unavailable, trying fallback');
      try {
        await _dio.patch(
            '${AppConstants.legacyAlertsBase}/$alertId/mark_as_read/');
      } catch (_) {
        AppLogger.w('Legacy mark-as-read endpoint unavailable');
      }
    }
  }
}

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService(
    ref.watch(protectedDioProvider),
    ref.watch(patientServiceProvider),
  );
});
