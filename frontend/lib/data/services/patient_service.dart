import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/patient_model.dart';
import 'dio_client.dart';

class PatientService {
  final Dio _dio;
  const PatientService(this._dio);

  /// GET /patients/PatientService/{patientId}/get_patient_by_id/
  /// Backend returns: { success: true, patient: { ... } }
  Future<Patient> getProfile(int patientId) async {
    try {
      final url = '${AppConstants.patientById}$patientId/get_patient_by_id/';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        // Backend wraps patient data in 'patient' key
        if (data['success'] == true && data['patient'] != null) {
          return Patient.fromJson(data['patient'] as Map<String, dynamic>);
        }
        return Patient.fromJson(data);
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      AppLogger.e('Patient profile failed', e);
      rethrow;
    }
  }

  /// PATCH /patients/PatientService/{patientId}/update_patient/
  /// Backend returns: { success: true, message: '...' } (no patient object)
  /// We re-fetch the profile after a successful update.
  Future<Patient> updateProfile(int patientId, Map<String, dynamic> data) async {
    try {
      final url = '${AppConstants.patientUpdate}$patientId/update_patient/';
      final response = await _dio.patch(url, data: data);
      if (response.statusCode == 200 && response.data != null) {
        final respData = response.data as Map<String, dynamic>;
        if (respData['success'] == true) {
          // Backend doesn't return the patient object, so re-fetch it
          return await getProfile(patientId);
        }
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      AppLogger.w('Patient update failed');
      rethrow;
    }
  }
}

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(ref.watch(protectedDioProvider));
});
