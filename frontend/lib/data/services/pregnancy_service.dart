import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/pregnancy_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import 'patient_service.dart';

class PregnancyService {
  final Dio _dio;
  final PatientService _patientService;
  const PregnancyService(this._dio, this._patientService);

  Future<List<Pregnancy>> getPregnancies() async {
    try {
      final response = await _dio.get(AppConstants.pregnancies);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Pregnancy.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load pregnancies');
    } catch (e) {
      AppLogger.w('Primary pregnancies endpoint unavailable, trying fallback');
      try {
        final patient = await _patientService.getProfile();
        final patientId = patient.id;
        if (patientId != null) {
          final response = await _dio.get('${AppConstants.legacyPregnancyBase}/$patientId/get_current_pregnancy/');
          if (response.statusCode == 200 && response.data != null) {
            final data = response.data;
            if (data is List) {
              return data.map((e) => Pregnancy.fromJson(e as Map<String, dynamic>)).toList();
            }
            if (data is Map<String, dynamic>) {
              return [Pregnancy.fromJson(data)];
            }
          }
        }
      } catch (_) {
        AppLogger.w('Legacy pregnancy endpoint unavailable, using mock data');
      }
      return [MockData.activePregnancy];
    }
  }

  Future<Pregnancy?> getActivePregnancy() async {
    final pregnancies = await getPregnancies();
    try {
      return pregnancies.firstWhere((p) => p.isActive);
    } catch (_) {
      return pregnancies.isNotEmpty ? pregnancies.first : null;
    }
  }

  Future<Pregnancy> createPregnancy(Pregnancy pregnancy) async {
    try {
      final response = await _dio.post(AppConstants.pregnancies, data: pregnancy.toJson());
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return Pregnancy.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create pregnancy');
    } catch (e) {
      AppLogger.w('Primary create pregnancy endpoint unavailable, trying fallback');
      final response = await _dio.post('${AppConstants.legacyPregnancyBase}/create_pregnancy/', data: pregnancy.toJson());
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return Pregnancy.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create pregnancy');
    }
  }

  Future<Pregnancy> updatePregnancy(Pregnancy pregnancy, Map<String, dynamic> data) async {
    final id = pregnancy.id;
    if (id == null) throw Exception('Pregnancy id is required');
    try {
      final response = await _dio.patch('${AppConstants.pregnancies}$id/', data: data);
      if ((response.statusCode == 200 || response.statusCode == 202) && response.data != null) {
        return Pregnancy.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update pregnancy');
    } catch (e) {
      AppLogger.w('Primary update pregnancy endpoint unavailable, trying fallback');
      final response = await _dio.patch('${AppConstants.legacyPregnancyBase}/$id/update_pregnancy/', data: data);
      if ((response.statusCode == 200 || response.statusCode == 202) && response.data != null) {
        return Pregnancy.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update pregnancy');
    }
  }
}

final pregnancyServiceProvider = Provider<PregnancyService>((ref) {
  return PregnancyService(
    ref.watch(protectedDioProvider),
    ref.watch(patientServiceProvider),
  );
});
