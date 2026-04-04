import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/doctor_model.dart';
import 'dio_client.dart';

class DoctorService {
  final Dio _dio;
  const DoctorService(this._dio);

  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await _dio.get(AppConstants.doctorsList);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load doctors');
    } catch (e) {
      AppLogger.w('Primary doctors list endpoint unavailable, trying fallback');
      final response = await _dio.get(AppConstants.legacyDoctorsList);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load doctors');
    }
  }
}

final doctorServiceProvider = Provider<DoctorService>((ref) {
  return DoctorService(ref.watch(protectedDioProvider));
});
