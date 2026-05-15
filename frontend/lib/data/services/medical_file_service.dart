import 'package:dio/dio.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';

class MedicalFileService {
  final Dio _dio = DioClient().dio;

  /// GET /medical_files/MedicalFileService/{pk}/get_patient_medical_files/
  /// Returns: {success, medical_files: [{id, type, file, upload_date, patient_id, patient}]}
  Future<Map<String, dynamic>> getPatientMedicalFiles(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getPatientMedicalFiles(patientId));
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// POST /medical_files/MedicalFileService/create_attachment/
  /// Sends multipart form data: type (string), file (file), patient_id (int)
  /// Returns: {success, message, attachment: {id, type, file, upload_date, patient_id}}
  Future<Map<String, dynamic>> createAttachment({
    required int patientId,
    required String type,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'patient_id': patientId,
        'type': type,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        ApiEndpoints.createAttachment,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// DELETE /medical_files/MedicalFileService/{pk}/delete_attachment/
  /// Returns: {success, message}
  Future<Map<String, dynamic>> deleteAttachment(int attachmentId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.deleteAttachment(attachmentId));
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// POST /medical_files/MedicalFileService/request_medical_access/
  /// Doctor requests access to patient's files → creates PENDING record + alert to patient
  Future<Map<String, dynamic>> requestMedicalAccess({
    required int patientId,
    required int doctorId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.requestMedicalAccess,
        data: {'patient_id': patientId, 'doctor_id': doctorId},
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// POST /medical_files/MedicalFileService/create_patient_doctor_access/
  /// Patient accepts a doctor's access request (PENDING → ACCEPTED)
  Future<Map<String, dynamic>> acceptDoctorAccess({
    required int patientId,
    required int doctorId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createPatientDoctorAccess,
        data: {'patient_id': patientId, 'doctor_id': doctorId},
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// GET /medical_files/MedicalFileService/{pk}/get_doctor_patients/
  /// Returns list of patients the doctor has ACCEPTED access to
  Future<Map<String, dynamic>> getDoctorPatients(int doctorId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getDoctorPatients(doctorId));
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// GET /medical_files/MedicalFileService/{pk}/get_patient_doctors_requests/
  /// Returns list of doctors with PENDING access requests for patient
  Future<Map<String, dynamic>> getPatientDoctorsRequests(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getPatientDoctorsRequests(patientId));
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// GET /medical_files/MedicalFileService/{pk}/get_patient_doctors/
  /// Returns list of doctors with ACCEPTED access to patient's files
  Future<Map<String, dynamic>> getPatientDoctors(int patientId) async {
    try {
      final response = await _dio.get(ApiEndpoints.getPatientDoctors(patientId));
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// DELETE /medical_files/MedicalFileService/{pk}/delete_patient_doctor_access/
  Future<Map<String, dynamic>> deletePatientDoctorAccess(int accessId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.deletePatientDoctorAccess(accessId));
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// DELETE /medical_files/MedicalFileService/revoke_access/
  /// Patient revokes a doctor's access (no access ID needed — uses patient+doctor IDs)
  Future<Map<String, dynamic>> revokeAccess({
    required int patientId,
    required int doctorId,
  }) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.revokeAccess,
        data: {'patient_id': patientId, 'doctor_id': doctorId},
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      return _err(e);
    }
  }

  /// GET /patients/PatientService/search/?q=<query>
  /// Returns paginated list of patients matching the query
  Future<Map<String, dynamic>> searchPatients(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.searchPatients,
        queryParameters: {'q': query},
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      // 404 means no patient found — return empty results, not an error
      if (e.response?.statusCode == 404) {
        return {'success': true, 'results': [], 'count': 0};
      }
      return _err(e);
    }
  }

  /// GET /doctors/DoctorService/search/?q=<query>
  /// Returns paginated list of doctors matching the query
  Future<Map<String, dynamic>> searchDoctors(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.searchDoctors,
        queryParameters: {'q': query},
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      // 404 means no doctor found — return empty results, not an error
      if (e.response?.statusCode == 404) {
        return {'success': true, 'results': [], 'count': 0};
      }
      return _err(e);
    }
  }

  Map<String, dynamic> _err(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      String msg;
      if (data is Map) {
        msg = data['message']?.toString()
            ?? data['detail']?.toString()
            ?? data['non_field_errors']?.toString()
            ?? _statusMessage(e.response?.statusCode);
      } else {
        msg = _statusMessage(e.response?.statusCode);
      }
      return {'success': false, 'message': msg};
    }
    return {'success': false, 'message': e.toString()};
  }

  String _statusMessage(int? code) {
    switch (code) {
      case 400: return 'Données invalides ou accès déjà existant';
      case 401: return 'Non autorisé. Veuillez vous reconnecter';
      case 403: return 'Accès refusé';
      case 404: return 'Ressource introuvable';
      case 409: return 'Cet accès existe déjà';
      case 500: return 'Erreur serveur, réessayez plus tard';
      default: return 'Erreur réseau (${code ?? 'inconnu'})';
    }
  }
}
