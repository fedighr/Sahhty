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
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // Backend returns: { success: true, doctors: [...] }
        // Each doctor is a flat map with fields from DoctorService.getAllDoctors()
        if (data is Map<String, dynamic>) {
          if (data['doctors'] is List) {
            return (data['doctors'] as List)
                .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
        // Fallback: backend might return a raw list
        if (data is List) {
          return data
              .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.e('Doctors list failed', e);
      return [];
    }
  }
}

final doctorServiceProvider = Provider<DoctorService>((ref) {
  return DoctorService(ref.watch(protectedDioProvider));
});
