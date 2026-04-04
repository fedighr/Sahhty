import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/pregnancy_model.dart';
import 'dio_client.dart';

class PregnancyService {
  final Dio _dio;
  const PregnancyService(this._dio);

  Future<List<Pregnancy>> getPregnancies(int patientId) async {
    try {
      // Backend doesn't have a list endpoint; get active pregnancy as a list
      final pregnancy = await getActivePregnancy(patientId);
      return pregnancy != null ? [pregnancy] : [];
    } catch (e) {
      AppLogger.e('Pregnancies list failed', e);
      rethrow;
    }
  }

  /// GET /pregnancies/PregnancyService/{patientId}/get_current_pregnancy/
  /// Backend returns: { success: true, pregnancy: { ... } }
  Future<Pregnancy?> getActivePregnancy(int patientId) async {
    try {
      final url = '${AppConstants.activePregnancy}$patientId/get_current_pregnancy/';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // Backend wraps response in { success: true, pregnancy: {...} }
          if (data['success'] == true && data['pregnancy'] != null) {
            return Pregnancy.fromJson(data['pregnancy'] as Map<String, dynamic>);
          }
          if (data.containsKey('test_date')) {
            return Pregnancy.fromJson(data);
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.e('Active pregnancy failed', e);
      return null; // Return null instead of rethrowing to be graceful
    }
  }

  Future<Pregnancy> createPregnancy(Pregnancy pregnancy) async {
    try {
      final response = await _dio.post(AppConstants.pregnancyCreate, data: pregnancy.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data != null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            // Backend wraps in { success: true, pregnancy: {...} }
            if (data['success'] == true && data['pregnancy'] != null) {
              return Pregnancy.fromJson(data['pregnancy'] as Map<String, dynamic>);
            }
            if (data.containsKey('test_date')) {
              return Pregnancy.fromJson(data);
            }
            return Pregnancy.fromJson(data);
          }
        }
      }
      throw Exception('Failed to create pregnancy');
    } catch (e) {
      AppLogger.w('Create pregnancy failed');
      rethrow;
    }
  }
}

final pregnancyServiceProvider = Provider<PregnancyService>((ref) {
  return PregnancyService(ref.watch(protectedDioProvider));
});
