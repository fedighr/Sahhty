import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

/// Service for Medications & Treatments
/// Backend: /medications/medicationsService/
class MedicationService {
  final Dio _dio = DioClient().dio;

  /// GET /medications/medicationsService/{patientId}/get_treatments_by_patient_id/
  /// Returns: [{id, start_date, end_date, dose, frequency, medication: {...}, schedules: [...]}]
  Future<Map<String, dynamic>> getTreatmentsByPatientId(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getTreatmentsByPatientId(patientId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /medications/medicationsService/search/?q=query
  /// Returns: {count, results: [{id, name, commercial_name, form, dosage, ...}]}
  Future<Map<String, dynamic>> searchMedications(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.searchMedications,
        queryParameters: {'q': query},
      );
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// POST /medications/medicationsService/create_treatment_with_schedules/
  /// Expects: {treatment: {start_date, end_date?, dose, frequency, patient_id, medication_id},
  ///           schedules: [{dose_time}]}
  Future<Map<String, dynamic>> createTreatmentWithSchedules(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.createTreatmentWithSchedules, data: data);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// DELETE /medications/medicationsService/{treatmentId}/delete_treatment_by_id/
  Future<Map<String, dynamic>> deleteTreatmentById(int treatmentId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.deleteTreatmentById(treatmentId));
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
