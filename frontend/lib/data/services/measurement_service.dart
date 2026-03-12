import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/measurement_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';

class MeasurementService {
  final Dio _dio;
  const MeasurementService(this._dio);

  Future<Map<String, dynamic>> createMeasurement(Measurement measurement) async {
    try {
      final response = await _dio.post(
        AppConstants.createMeasurement,
        data: measurement.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
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
      AppLogger.w('Measurements list endpoint not available, using mock data');
      if (type != null) {
        return MockData.recentMeasurements.where((m) => m.type == type).toList();
      }
      return MockData.recentMeasurements;
    }
  }

  Future<List<Measurement>> getLatestMeasurements() async {
    try {
      final response = await _dio.get(AppConstants.measurementsLatest);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load latest measurements');
    } catch (e) {
      AppLogger.w('Latest measurements endpoint not available, using mock data');
      return MockData.recentMeasurements;
    }
  }

  Future<RiskAssessment?> getLatestRiskAssessment() async {
    try {
      final response = await _dio.get(AppConstants.riskAssessments);
      if (response.statusCode == 200 && response.data != null) {
        return RiskAssessment.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      AppLogger.w('Risk assessment endpoint not available, using mock data');
      return MockData.latestRisk;
    }
  }
}

final measurementServiceProvider = Provider<MeasurementService>((ref) {
  return MeasurementService(ref.watch(protectedDioProvider));
});
