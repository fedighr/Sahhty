import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

class DoctorService {
  final Dio _dio = DioClient().dio;

  /// GET /doctors/DoctorService/get_all_doctors/
  Future<Map<String, dynamic>> getAllDoctors() async {
    try {
      final response = await _dio.get(ApiEndpoints.getAllDoctors);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /doctors/DoctorService/{pk}/get_doctor_by_id/
  Future<Map<String, dynamic>> getDoctorById(int doctorId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getDoctorById(doctorId));
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
