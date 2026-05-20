import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

class DoctorService {
  final Dio _dio = DioClient().dio;

  /// POST /doctors/DoctorService/create_doctor/
  Future<Map<String, dynamic>> createDoctor(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.createDoctor, data: data);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /doctors/DoctorService/get_all_doctors/
  Future<Map<String, dynamic>> getAllDoctors({String? speciality, String? ville, String? gender}) async {
    try {
      final Map<String, dynamic> params = {};
      if (speciality != null && speciality.isNotEmpty) params['speciality'] = speciality;
      if (ville != null && ville.isNotEmpty) params['ville'] = ville;
      if (gender != null && gender.isNotEmpty) params['gender'] = gender;
      final response = await _dio.get(
        ApiEndpoints.getAllDoctors,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = response.data;
      // Backend returns paginated format: {count, next, previous, results: [...]}
      if (data is Map && data.containsKey('results')) {
        return {
          'success': true,
          'doctors': data['results'],
          'count': data['count'],
          'next': data['next'],
          'previous': data['previous'],
        };
      }
      if (data is Map && data.containsKey('success')) {
        return Map<String, dynamic>.from(data);
      }
      return {'success': false, 'message': 'Format de réponse inattendu'};
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

  /// PATCH /doctors/DoctorService/{pk}/update_doctor/
  Future<Map<String, dynamic>> updateDoctor(int doctorId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiEndpoints.updateDoctor(doctorId), data: data);
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

  /// POST /doctors/DoctorService/add_doctor_schedule/
  Future<Map<String, dynamic>> addDoctorSchedule(List<Map<String, dynamic>> schedules) async {
    try {
      final response = await _dio.post(ApiEndpoints.addDoctorSchedule, data: schedules);
      if (response.data is Map<String, dynamic>) {
        return {'success': true, ...(response.data as Map<String, dynamic>)};
      }
      return {'success': true};
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

  /// GET /doctors/DoctorService/get_all_specialities/
  Future<Map<String, dynamic>> getSpecialities() async {
    try {
      final response = await _dio.get(ApiEndpoints.getAllSpecialities);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// PATCH /doctors/DoctorService/{pk}/update_doctor/ — save location
  Future<Map<String, dynamic>> updateDoctorLocation(int doctorId, double latitude, double longitude) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.updateDoctor(doctorId),
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return response.data ?? {'success': true};
    } on DioException catch (e) {
      return _err(e);
    }
  }

  Map<String, dynamic> _err(DioException e) {
    if (e.response?.data is Map<String, dynamic>) return e.response!.data;
    return {'success': false, 'message': e.message ?? 'Erreur réseau'};
  }
}
