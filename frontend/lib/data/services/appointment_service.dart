import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

/// Calls /appointments/AppointmentService/ endpoints
class AppointmentService {
  final Dio _dio = DioClient().dio;

  /// POST create_appointment
  /// Expects: {appointment_date, reason?, patient_id, doctor_id}
  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.createAppointment, data: data);
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// PUT /appointments/AppointmentService/{pk}/confirm_appointment/
  Future<Map<String, dynamic>> confirmAppointment(int appointmentId) async {
    try {
      final response = await _dio.put(ApiEndpoints.confirmAppointment(appointmentId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// PUT /appointments/AppointmentService/{pk}/cancel_appointment/
  /// Expects body: {cancelled_by: 'patient'|'doctor'}
  Future<Map<String, dynamic>> cancelAppointment(int appointmentId, String cancelledBy) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.cancelAppointment(appointmentId),
        data: {'cancelled_by': cancelledBy},
      );
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /appointments/AppointmentService/{patientId}/get_patient_today_appointments/
  /// Returns today's appointments for the patient
  Future<Map<String, dynamic>> getPatientTodayAppointments(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getPatientTodayAppointments(patientId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /appointments/AppointmentService/{doctorId}/get_doctor_today_appointments/
  Future<Map<String, dynamic>> getDoctorTodayAppointments(int doctorId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getDoctorTodayAppointments(doctorId));
      return response.data;
    } on DioException catch (e) {
      return _err(e);
    }
  }

  /// GET /appointments/AppointmentService/{doctorId}/get_doctor_appointments/
  Future<Map<String, dynamic>> getDoctorAllAppointments(int doctorId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getDoctorAllAppointments(doctorId));
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
