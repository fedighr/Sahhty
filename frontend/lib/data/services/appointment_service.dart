import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/appointment_model.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';

class AppointmentService {
  final Dio _dio;
  const AppointmentService(this._dio);

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await _dio.get(AppConstants.appointments);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load appointments');
    } catch (e) {
      AppLogger.w('Appointments endpoint not available, using mock data');
      return MockData.appointments;
    }
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    try {
      final response = await _dio.get(AppConstants.appointmentsUpcoming);
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to load upcoming appointments');
    } catch (e) {
      AppLogger.w('Upcoming appointments not available, using mock data');
      return MockData.appointments.where((a) => a.isUpcoming).toList();
    }
  }

  Future<Appointment> createAppointment(Appointment appointment) async {
    try {
      final response = await _dio.post(AppConstants.appointments, data: appointment.toJson());
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return Appointment.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create appointment');
    } catch (e) {
      AppLogger.e('Create appointment failed', e);
      rethrow;
    }
  }

  Future<void> updateAppointmentStatus(int id, String status) async {
    try {
      await _dio.patch('${AppConstants.appointments}$id/', data: {'status': status});
    } catch (e) {
      AppLogger.e('Update appointment status failed', e);
      rethrow;
    }
  }
}

final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  return AppointmentService(ref.watch(protectedDioProvider));
});
