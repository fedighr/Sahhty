import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../models/appointment_model.dart';
import 'dio_client.dart';

/// NOTE: The backend appointments module is NOT yet implemented.
/// All methods gracefully return empty data until the backend is ready.
class AppointmentService {
  final Dio _dio;
  const AppointmentService(this._dio);

  Future<List<Appointment>> getAppointments() async {
    // Backend /appointments/ is not registered in config/urls.py yet
    AppLogger.w('Appointments: backend endpoint not available yet');
    return [];
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    // Backend /appointments/upcoming/ is not registered in config/urls.py yet
    AppLogger.w('Upcoming appointments: backend endpoint not available yet');
    return [];
  }

  Future<Appointment?> createAppointment(Appointment appointment) async {
    AppLogger.w('Create appointment: backend endpoint not available yet');
    return null;
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    AppLogger.w('Update appointment status: backend endpoint not available yet');
  }
}

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(ref.watch(protectedDioProvider));
});
