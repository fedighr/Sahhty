import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

/// Calls /patients/PatientService/ endpoints
class PatientService {
  final Dio _dio = DioClient().dio;

  /// POST create_patient — expects {email, height, weight, blood_type, ...}
  /// For females also nested menstrual_cycle info
  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.createPatient, data: data);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /patients/PatientService/{pk}/get_patient_by_id/
  /// Returns: {success, patient: {first_name, last_name, email, birth_date, age,
  ///   phone, gender, height, weight, blood_type, chronic_diseases, allergies,
  ///   current_medications, family_doctor_name, menstrual_cycle?: {...}}}
  Future<Map<String, dynamic>> getPatientById(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getPatientById(patientId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// PATCH /patients/PatientService/{pk}/update_patient/
  Future<Map<String, dynamic>> updatePatient(int patientId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiEndpoints.updatePatient(patientId), data: data);
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
