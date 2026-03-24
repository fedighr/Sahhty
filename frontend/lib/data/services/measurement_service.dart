import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/measurement_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import 'patient_service.dart';

class MeasurementService {
  final Dio _dio;
  final PatientService _patientService;
  const MeasurementService(this._dio, this._patientService);

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

  Future<List<Measurement>> getMeasurements({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      final response = await _dio.get(AppConstants.measurementsList, queryParameters: queryParams);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load measurements');
    } catch (e) {
      AppLogger.w('Primary measurements endpoint unavailable, trying fallback');
      try {
        final patient = await _patientService.getProfile();
        final patientId = patient.id;
        if (patientId != null) {
          final response = await _dio.get('${AppConstants.legacyMeasurementsByPatient}/$patientId/get_patient_measurements/');
          if (response.statusCode == 200 && response.data is List) {
            final items = (response.data as List)
                .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
                .toList();
            if (type != null) return items.where((m) => m.type == type).toList();
            return items;
          }
        }
      } catch (_) {
        AppLogger.w('Legacy measurements endpoint unavailable, using mock data');
      }
      if (type != null) {
        return MockData.recentMeasurements.where((m) => m.type == type).toList();
      }
      return MockData.recentMeasurements;
    }
  }

  Future<List<Measurement>> getLatestMeasurements() async {
    final all = await getMeasurements();
    final grouped = <String, Measurement>{};
    for (final measurement in all) {
      final current = grouped[measurement.type];
      if (current == null) {
        grouped[measurement.type] = measurement;
        continue;
      }
      final currentDate = DateTime.tryParse(current.measurementDate ?? '');
      final nextDate = DateTime.tryParse(measurement.measurementDate ?? '');
      if (nextDate != null && (currentDate == null || nextDate.isAfter(currentDate))) {
        grouped[measurement.type] = measurement;
      }
    }
    return grouped.values.toList();
  }

  Future<RiskAssessment?> getLatestRiskAssessment() async {
    try {
      final response = await _dio.get(AppConstants.riskAssessments);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return RiskAssessment.fromJson(data.first as Map<String, dynamic>);
        }
        if (data is Map<String, dynamic>) {
          return RiskAssessment.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      AppLogger.w('Primary risk assessment endpoint unavailable, trying fallback');
      try {
        final patient = await _patientService.getProfile();
        final patientId = patient.id;
        if (patientId != null) {
          final response = await _dio.get('${AppConstants.legacyRiskAssessmentsByPatient}/$patientId/get_risk_assessment/');
          if (response.statusCode == 200 && response.data != null) {
            final data = response.data;
            if (data is List && data.isNotEmpty) {
              return RiskAssessment.fromJson(data.first as Map<String, dynamic>);
            }
            if (data is Map<String, dynamic>) {
              return RiskAssessment.fromJson(data);
            }
          }
        }
      } catch (_) {
        AppLogger.w('Legacy risk assessment endpoint unavailable, using mock data');
      }
      return MockData.latestRisk;
    }
  }
}

final measurementServiceProvider = Provider<MeasurementService>((ref) {
  return MeasurementService(
    ref.watch(protectedDioProvider),
    ref.watch(patientServiceProvider),
  );
});
