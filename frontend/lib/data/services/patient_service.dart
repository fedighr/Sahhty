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
      AppLogger.w('Patient profile endpoint not available, using mock data');
      return MockData.patient;
    }
  }

  Future<Patient> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(AppConstants.patientUpdate, data: data);
      if (response.statusCode == 200 && response.data != null) {
        return Patient.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      AppLogger.w('Patient update endpoint not available');
      rethrow;
    }
  }
}

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(ref.watch(protectedDioProvider));
});
