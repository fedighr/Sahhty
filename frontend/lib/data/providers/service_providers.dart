import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahhty/data/services/auth_service.dart';
import 'package:sahhty/data/services/patient_service.dart';
import 'package:sahhty/data/services/pregnancy_service.dart';
import 'package:sahhty/data/services/measurement_service.dart';
import 'package:sahhty/data/services/alert_service.dart';
import 'package:sahhty/data/services/doctor_service.dart';
import 'package:sahhty/data/services/medication_service.dart';
import 'package:sahhty/data/services/health_connect_service.dart';
import 'package:sahhty/data/services/vitals_sync_service.dart';
import 'package:sahhty/data/services/appointment_service.dart';
import 'package:sahhty/data/services/medical_file_service.dart';
import 'package:sahhty/data/services/wear_listener_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final patientServiceProvider = Provider<PatientService>((ref) => PatientService());
final pregnancyServiceProvider = Provider<PregnancyService>((ref) => PregnancyService());
final measurementServiceProvider = Provider<MeasurementService>((ref) => MeasurementService());
final alertServiceProvider = Provider<AlertService>((ref) => AlertService());
final doctorServiceProvider = Provider<DoctorService>((ref) => DoctorService());
final medicationServiceProvider = Provider<MedicationService>((ref) => MedicationService());
final appointmentServiceProvider = Provider<AppointmentService>((ref) => AppointmentService());
final healthConnectServiceProvider = Provider<HealthConnectService>((ref) => HealthConnectService());
final vitalsSyncServiceProvider = Provider<VitalsSyncService>((ref) => VitalsSyncService(
  healthConnect: ref.read(healthConnectServiceProvider),
  measurementService: ref.read(measurementServiceProvider),
));
final medicalFileServiceProvider = Provider<MedicalFileService>((ref) => MedicalFileService());

final wearListenerServiceProvider = Provider<WearListenerService>((ref) {
  final service = WearListenerService();
  ref.onDispose(service.stop);
  return service;
});

