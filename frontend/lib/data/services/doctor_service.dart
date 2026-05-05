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

  /// GET /doctors/DoctorService/search/?q=query (paginated)
  Future<Map<String, dynamic>> searchDoctors(String q) async {
    try {
      final response = await _dio.get(ApiEndpoints.searchDoctors, queryParameters: {'q': q});
      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        return {
          'success': true,
          'doctors': data['results'],
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      }
      return data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET any paginated URL (for next/previous navigation)
  Future<Map<String, dynamic>> getDoctorsByUrl(String url) async {
    try {
      final response = await _dio.get(url);
      final data = response.data;
      if (data is Map && data.containsKey('results')) {
        return {
          'success': true,
          'doctors': data['results'],
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      }
      return {'success': false, 'message': 'Format de réponse inattendu'};
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

  /// GET /doctors/DoctorService/{pk}/get_doctor_schedule/
  Future<Map<String, dynamic>> getDoctorSchedule(int doctorId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getDoctorSchedule(doctorId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /doctors/DoctorService/{pk}/get_doctor_available_slots/?day=MONDAY&date=2026-05-05
  Future<Map<String, dynamic>> getDoctorAvailableSlots(int doctorId, String day, String date) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getDoctorAvailableSlots(doctorId),
        queryParameters: {'day': day, 'date': date},
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
