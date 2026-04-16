import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

class MeasurementService {
  final Dio _dio = DioClient().dio;

  /// POST /measurements/MeasurementService/create_measurement/
  /// Backend expects: {type, value1, value2?, unit, context?, patient_id}
  /// Returns: {success, risk_level?, message}
  Future<Map<String, dynamic>> createMeasurement(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.createMeasurement, data: data);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET latest measurements for a patient
  /// Returns: {success, height, weight, bmi, glycemia_informations, blood_pressure,
  ///   heart_rate, body_temp, pregnancy_week}
  Future<Map<String, dynamic>> getLatestMeasurements(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getLatestMeasurements(patientId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET all measurements for a patient
  /// Returns: {success, measurements: [{id, type, measurement_date, value1, value2, unit, context, patient_id}]}
  Future<Map<String, dynamic>> getPatientMeasurements(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getPatientMeasurements(patientId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET risk assessment for a patient
  /// Returns: {success, risk_assessment: {assessed_at, global_risk_level, personal_risk_level,
  ///   personal_risk_note, glucose_used, bp_sys_used, bp_dia_used, heart_rate_used, weight_used}}
  Future<Map<String, dynamic>> getRiskAssessment(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getRiskAssessment(patientId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// POST /measurements/MeasurementService/sync_smartwatch/
  /// Sends a batch of readings from Health Connect. Backend saves them and returns
  /// the newly created Measurement objects on 201.
  /// Body: { patient_id: int, readings: [{type, value1, value2?, unit, context?}] }
  /// Response 201: { saved: int, measurements: [...] }
  Future<Map<String, dynamic>> syncSmartwatch({
    required int patientId,
    required List<Map<String, dynamic>> readings,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.syncSmartwatch,
        data: {
          'patient_id': patientId,
          'readings': readings,
        },
      );
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
