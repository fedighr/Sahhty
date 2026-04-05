import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahhty/data/services/auth_service.dart';
import 'package:sahhty/data/services/patient_service.dart';
import 'package:sahhty/data/services/pregnancy_service.dart';
import 'package:sahhty/data/services/measurement_service.dart';
import 'package:sahhty/data/services/alert_service.dart';
import 'package:sahhty/data/services/doctor_service.dart';

/// Single instances of each service
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final patientServiceProvider = Provider<PatientService>((ref) => PatientService());
final pregnancyServiceProvider = Provider<PregnancyService>((ref) => PregnancyService());
final measurementServiceProvider = Provider<MeasurementService>((ref) => MeasurementService());
final alertServiceProvider = Provider<AlertService>((ref) => AlertService());
final doctorServiceProvider = Provider<DoctorService>((ref) => DoctorService());
