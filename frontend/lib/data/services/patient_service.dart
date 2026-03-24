import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/patient_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';

class PatientService {
  final Dio _dio;
  const PatientService(this._dio);

  Future<Patient> getProfile() async {
    try {
      final response = await _dio.get(AppConstants.patientProfile);
      if (response.statusCode == 200 && response.data != null) {
        return Patient.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      AppLogger.w('Primary patient profile endpoint unavailable, trying fallback');
      try {
        final fallback = await _dio.get(AppConstants.legacyPatientProfile);
        if (fallback.statusCode == 200 && fallback.data != null) {
          return Patient.fromJson(fallback.data as Map<String, dynamic>);
        }
      } catch (_) {
        AppLogger.w('Legacy patient profile endpoint unavailable, using mock data');
      }
      return MockData.patient;
    }
  }

  Future<Patient> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(AppConstants.patientUpdate, data: data);
      if ((response.statusCode == 200 || response.statusCode == 202) && response.data != null) {
        return Patient.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      AppLogger.w('Primary patient update endpoint unavailable, trying fallback');
      final profile = await getProfile();
      final patientId = profile.id;
      if (patientId == null) rethrow;
      final fallback = await _dio.patch('/patients/PatientService/$patientId/update_patient/', data: data);
      if ((fallback.statusCode == 200 || fallback.statusCode == 202) && fallback.data != null) {
        return Patient.fromJson(fallback.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update profile');
    }
  }
}

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(ref.watch(protectedDioProvider));
});
