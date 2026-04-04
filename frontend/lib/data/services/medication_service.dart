import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../models/medication_model.dart';
import 'dio_client.dart';

/// NOTE: The backend medications module is NOT yet implemented.
/// All methods gracefully return empty data until the backend is ready.
class MedicationService {
  final Dio _dio;
  const MedicationService(this._dio);

  Future<List<Treatment>> getTreatments() async {
    // Backend /medications/ is not registered in config/urls.py yet
    AppLogger.w('Treatments: backend endpoint not available yet');
    return [];
  }

  Future<List<Treatment>> getActiveTreatments() async {
    return [];
  }

  Future<Treatment?> createTreatment(Treatment treatment) async {
    AppLogger.w('Create treatment: backend endpoint not available yet');
    return null;
  }
}

final medicationServiceProvider = Provider<MedicationService>((ref) {
  return MedicationService(ref.watch(protectedDioProvider));
});
