import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/medication_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';

class MedicationService {
  final Dio _dio;
  const MedicationService(this._dio);

  Future<List<Treatment>> getTreatments() async {
    try {
      final response = await _dio.get(AppConstants.treatments);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Treatment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load treatments');
    } catch (e) {
      AppLogger.w('Treatments endpoint not available, using mock data');
      return MockData.treatments;
    }
  }

  Future<List<Treatment>> getActiveTreatments() async {
    final all = await getTreatments();
    return all.where((t) => t.isActive).toList();
  }

  Future<Treatment> createTreatment(Treatment treatment) async {
    try {
      final response = await _dio.post(AppConstants.treatments, data: treatment.toJson());
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return Treatment.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create treatment');
    } catch (e) {
      AppLogger.e('Create treatment failed', e);
      rethrow;
    }
  }
}

final medicationServiceProvider = Provider<MedicationService>((ref) {
  return MedicationService(ref.watch(protectedDioProvider));
});
