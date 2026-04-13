import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

class PregnancyService {
  final Dio _dio = DioClient().dio;

  /// POST create_pregnancy
  /// Backend expects: {test_date, test_result, start_date?, due_date?, end_date?, patient}
  Future<Map<String, dynamic>> createPregnancy(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.createPregnancy, data: data);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /pregnancies/PregnancyService/{patientId}/get_current_pregnancy/
  /// Returns: {success, pregnancy: {id, test_date, test_result, start_date, due_date, end_date, patient}}
  Future<Map<String, dynamic>> getCurrentPregnancy(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getCurrentPregnancy(patientId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// PATCH /pregnancies/PregnancyService/{pregnancyId}/update_pregnancy/
  Future<Map<String, dynamic>> updatePregnancy(int pregnancyId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiEndpoints.updatePregnancy(pregnancyId), data: data);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// DELETE /pregnancies/PregnancyService/{pregnancyId}/delete_pregnancy/
  Future<Map<String, dynamic>> deletePregnancy(int pregnancyId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.deletePregnancy(pregnancyId));
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
