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
  final String? displayName;

  const HomeData({
    this.patient,
    this.activePregnancy,
    this.recentMeasurements = const [],
    this.latestRisk,
    this.upcomingAppointments = const [],
    this.unreadAlerts = const [],
    this.isLoading = false,
    this.error,
    this.displayName,
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
    String? displayName,
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
        displayName: displayName ?? this.displayName,
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
      final displayName = await tokenStorage.getUserDisplayName();

      if (userId == null) {
        state = HomeData(isLoading: false, error: 'Utilisateur non identifié', displayName: displayName);
        return;
      }

      // Try storedPatientId first, then fall back to userId
      // NOTE: userId (User PK) may differ from patientId (Patient PK).
      // This is a known backend limitation — the login endpoint should return patient_id.
      final patientId = storedPatientId ?? userId;

      final patientService = ref.read(patientServiceProvider);
      final pregnancyService = ref.read(pregnancyServiceProvider);
      final measurementService = ref.read(measurementServiceProvider);
      final appointmentService = ref.read(appointmentServiceProvider);
      final alertService = ref.read(alertServiceProvider);

      // First, try to get the patient profile to validate patientId and save it.
      Patient? patient;
      int? confirmedPatientId;
      try {
        patient = await patientService.getProfile(patientId);
        confirmedPatientId = patient.id ?? patientId;
        // Save the patientId for future use if it differs from userId
        if (patient.id != null && storedPatientId == null) {
          await tokenStorage.savePatientId(patient.id!);
        }
      } catch (_) {
        // If patientId == userId and it failed, try to continue with userId.
        // The patient profile fetch may fail if userId != patientId (backend limitation).
        confirmedPatientId = patientId;
        patient = null;
      }

      // Load remaining data in parallel, catch each individually
      Pregnancy? activePregnancy;
      Map<String, dynamic>? latestMeasurementsMap;
      RiskAssessment? latestRisk;
      List<Appointment> upcomingAppointments = [];
      List<Alert> unreadAlerts = [];

      try {
        activePregnancy = await pregnancyService.getActivePregnancy(confirmedPatientId);
      } catch (_) {}

      try {
        latestMeasurementsMap = await measurementService.getLatestMeasurements(confirmedPatientId);
      } catch (_) {}

      try {
        latestRisk = await measurementService.getLatestRiskAssessment(confirmedPatientId);
      } catch (_) {}

      try {
        upcomingAppointments = await appointmentService.getUpcomingAppointments();
      } catch (_) {}

      try {
        unreadAlerts = await alertService.getUnreadAlerts(userId);
      } catch (_) {}

      state = HomeData(
        patient: patient,
        activePregnancy: activePregnancy,
        recentMeasurements: _buildMeasurementsFromMap(latestMeasurementsMap),
        latestRisk: latestRisk,
        upcomingAppointments: upcomingAppointments,
        unreadAlerts: unreadAlerts,
        isLoading: false,
        displayName: displayName,
      );
    } catch (e) {
      // Even if loading fails, show partial data rather than full error screen
      final tokenStorage = ref.read(tokenStorageServiceProvider);
      final displayName = await tokenStorage.getUserDisplayName();
      state = HomeData(
        isLoading: false,
        error: 'Impossible de charger les données. Vérifiez votre connexion.',
        displayName: displayName,
      );
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
