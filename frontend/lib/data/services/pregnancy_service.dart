import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/pregnancy_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';

class PregnancyService {
  final Dio _dio;
  const PregnancyService(this._dio);

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
      AppLogger.w('Pregnancies endpoint not available, using mock data');
      return [MockData.activePregnancy];
    }
  }

  Future<Pregnancy?> getActivePregnancy() async {
    try {
      final response = await _dio.get(AppConstants.activePregnancy);
      if (response.statusCode == 200 && response.data != null) {
        return Pregnancy.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      AppLogger.w('Active pregnancy endpoint not available, using mock data');
      return MockData.activePregnancy;
    }
  }

  Future<Pregnancy> createPregnancy(Pregnancy pregnancy) async {
    try {
      final response = await _dio.post(AppConstants.pregnancies, data: pregnancy.toJson());
      if (response.statusCode == 201 && response.data != null) {
        return Pregnancy.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create pregnancy');
    } catch (e) {
      AppLogger.w('Create pregnancy endpoint not available');
      rethrow;
    }
  }
}

final pregnancyServiceProvider = Provider<PregnancyService>((ref) {
  return PregnancyService(ref.watch(protectedDioProvider));
});
