import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/measurement_model.dart';
import 'dio_client.dart';

class MeasurementService {
  final Dio _dio;
  const MeasurementService(this._dio);

  /// POST /measurements/MeasurementService/create_measurement/
  /// Backend returns: { success: true, risk_level: ..., risk_percentage: ..., message: ... }
  Future<Map<String, dynamic>> createMeasurement(Measurement measurement) async {
    try {
      final response = await _dio.post(
        AppConstants.createMeasurement,
        data: measurement.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to create measurement');
    } catch (e) {
      AppLogger.e('Create measurement failed', e);
      rethrow;
    }
  }

  /// GET /measurements/MeasurementService/{patientId}/get_patient_measurements/
  /// Backend returns: { success: true, measurements: [...] }
  Future<List<Measurement>> getMeasurements(int patientId, {String? type}) async {
    try {
      final url = '${AppConstants.measurementsByPatient}$patientId/get_patient_measurements/';
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      final response = await _dio.get(url, queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['measurements'] is List) {
            return (data['measurements'] as List)
                .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
        if (data is List) {
          return data
              .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.e('Measurements list failed', e);
      rethrow;
    }
  }

  /// GET /measurements/MeasurementService/{patientId}/get_latest_measurements/
  /// Backend returns: { success: true, height: ..., weight: ..., bmi: ..., ... }
  Future<Map<String, dynamic>?> getLatestMeasurements(int patientId) async {
    try {
      final url = '${AppConstants.measurementsLatest}$patientId/get_latest_measurements/';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      AppLogger.e('Latest measurements failed', e);
      return null;
    }
  }

  /// GET /measurements/MeasurementService/{patientId}/get_risk_assessment/
  /// Backend returns: { success: true, risk_assessment: {...} }
  Future<RiskAssessment?> getLatestRiskAssessment(int patientId) async {
    try {
      final url = '${AppConstants.riskAssessment}$patientId/get_risk_assessment/';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true && data['risk_assessment'] != null) {
            return RiskAssessment.fromJson(data['risk_assessment'] as Map<String, dynamic>);
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.e('Risk assessment failed', e);
      return null;
    }
  }
}

final measurementServiceProvider = Provider<MeasurementService>((ref) {
  return MeasurementService(ref.watch(protectedDioProvider));
});
