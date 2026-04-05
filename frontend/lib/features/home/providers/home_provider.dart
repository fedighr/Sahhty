import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/services/patient_service.dart';
import '../../../data/services/pregnancy_service.dart';
import '../../../data/services/measurement_service.dart';
import '../../../data/services/appointment_service.dart';
import '../../../data/services/alert_service.dart';
import '../../../data/services/token_storage_service.dart';

/// Combined home data for the patient home screen
class HomeData {
  final Patient? patient;
  final Pregnancy? activePregnancy;
  final List<Measurement> recentMeasurements;
  final RiskAssessment? latestRisk;
  final List<Appointment> upcomingAppointments;
  final List<Alert> unreadAlerts;
  final bool isLoading;
  final String? error;

  const HomeData({
    this.patient,
    this.activePregnancy,
    this.recentMeasurements = const [],
    this.latestRisk,
    this.upcomingAppointments = const [],
    this.unreadAlerts = const [],
    this.isLoading = false,
    this.error,
  });

  HomeData copyWith({
    Patient? patient,
    Pregnancy? activePregnancy,
    List<Measurement>? recentMeasurements,
    RiskAssessment? latestRisk,
    List<Appointment>? upcomingAppointments,
    List<Alert>? unreadAlerts,
    bool? isLoading,
    String? error,
  }) =>
      HomeData(
        patient: patient ?? this.patient,
        activePregnancy: activePregnancy ?? this.activePregnancy,
        recentMeasurements: recentMeasurements ?? this.recentMeasurements,
        latestRisk: latestRisk ?? this.latestRisk,
        upcomingAppointments: upcomingAppointments ?? this.upcomingAppointments,
        unreadAlerts: unreadAlerts ?? this.unreadAlerts,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class HomeNotifier extends Notifier<HomeData> {
  @override
  HomeData build() {
    _loadData();
    return const HomeData(isLoading: true);
  }

  Future<void> _loadData() async {
    try {
      final tokenStorage = ref.read(tokenStorageServiceProvider);
      final storedPatientId = await tokenStorage.getPatientId();
      final userId = await tokenStorage.getUserId();

      // Try storedPatientId first, then fall back to userId
      // NOTE: userId (User PK) may differ from patientId (Patient PK).
      // This is a known backend limitation — the login endpoint should return patient_id.
      final patientId = storedPatientId ?? userId;

      if (patientId == null || userId == null) {
        state = const HomeData(isLoading: false, error: 'Utilisateur non identifié');
        return;
      }

      final patientService = ref.read(patientServiceProvider);
      final pregnancyService = ref.read(pregnancyServiceProvider);
      final measurementService = ref.read(measurementServiceProvider);
      final appointmentService = ref.read(appointmentServiceProvider);
      final alertService = ref.read(alertServiceProvider);

      // First, try to get the patient profile to validate patientId and save it
      Patient? patient;
      try {
        patient = await patientService.getProfile(patientId);
        // Save the patientId for future use if it differs from userId
        if (patient.id != null && storedPatientId == null) {
          await tokenStorage.savePatientId(patient.id!);
        }
      } catch (_) {
        patient = null;
      }

      // Use the confirmed patientId (from patient profile or fallback)
      final confirmedPatientId = patient?.id ?? patientId;

      // Load remaining data in parallel
      final results = await Future.wait([
        pregnancyService.getActivePregnancy(confirmedPatientId),
        measurementService.getLatestMeasurements(confirmedPatientId),
        measurementService.getLatestRiskAssessment(confirmedPatientId),
        appointmentService.getUpcomingAppointments(),
        alertService.getUnreadAlerts(userId),
      ]);

      state = HomeData(
        patient: patient,
        activePregnancy: results[0] as Pregnancy?,
        recentMeasurements: _buildMeasurementsFromMap(results[1] as Map<String, dynamic>?),
        latestRisk: results[2] as RiskAssessment?,
        upcomingAppointments: results[3] as List<Appointment>,
        unreadAlerts: results[4] as List<Alert>,
        isLoading: false,
      );
    } catch (e) {
      state = HomeData(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadData();
  }

  /// Convert backend getLatestMeasurements response map into List<Measurement>
  /// Backend returns: { weight, height, bmi, glycemia_informations: {value1, unit, ...},
  ///   blood_pressure: {value1, value2, unit, ...}, heart_rate: {value1, unit, ...} }
  List<Measurement> _buildMeasurementsFromMap(Map<String, dynamic>? data) {
    if (data == null) return [];
    final list = <Measurement>[];

    // Blood pressure
    final bp = data['blood_pressure'];
    if (bp is Map<String, dynamic>) {
      list.add(Measurement(
        type: 'BLOOD_PRESSURE',
        value1: _toDouble(bp['value1']),
        value2: bp['value2'] != null ? _toDouble(bp['value2']) : null,
        unit: bp['unit'] as String? ?? 'MMHG',
        measurementDate: bp['measurement_date']?.toString(),
      ));
    }

    // Weight
    final weight = data['weight'];
    if (weight != null) {
      list.add(Measurement(
        type: 'WEIGHT',
        value1: _toDouble(weight),
        unit: 'KG',
      ));
    }

    // Glycemia
    final glycemia = data['glycemia_informations'];
    if (glycemia is Map<String, dynamic>) {
      list.add(Measurement(
        type: 'GLYCEMIA',
        value1: _toDouble(glycemia['value1']),
        unit: glycemia['unit'] as String? ?? 'G_L',
        measurementDate: glycemia['measurement_date']?.toString(),
      ));
    }

    // Heart rate
    final hr = data['heart_rate'];
    if (hr is Map<String, dynamic>) {
      list.add(Measurement(
        type: 'HEART_RATE',
        value1: _toDouble(hr['value1']),
        unit: hr['unit'] as String? ?? 'BPM',
        measurementDate: hr['measurement_date']?.toString(),
      ));
    }

    return list;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeData>(HomeNotifier.new);
