import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/services/patient_service.dart';
import '../../../data/services/pregnancy_service.dart';
import '../../../data/services/measurement_service.dart';
import '../../../data/services/alert_service.dart';

/// Combined home data for the patient home screen
class HomeData {
  final Patient? patient;
  final Pregnancy? activePregnancy;
  final List<Measurement> recentMeasurements;
  final RiskAssessment? latestRisk;
  final List<Alert> unreadAlerts;
  final bool isLoading;
  final String? error;

  const HomeData({
    this.patient,
    this.activePregnancy,
    this.recentMeasurements = const [],
    this.latestRisk,
    this.unreadAlerts = const [],
    this.isLoading = false,
    this.error,
  });

  HomeData copyWith({
    Patient? patient,
    Pregnancy? activePregnancy,
    List<Measurement>? recentMeasurements,
    RiskAssessment? latestRisk,
    List<Alert>? unreadAlerts,
    bool? isLoading,
    String? error,
  }) =>
      HomeData(
        patient: patient ?? this.patient,
        activePregnancy: activePregnancy ?? this.activePregnancy,
        recentMeasurements: recentMeasurements ?? this.recentMeasurements,
        latestRisk: latestRisk ?? this.latestRisk,
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
      final patientService = ref.read(patientServiceProvider);
      final pregnancyService = ref.read(pregnancyServiceProvider);
      final measurementService = ref.read(measurementServiceProvider);
      final alertService = ref.read(alertServiceProvider);

      final results = await Future.wait([
        patientService.getProfile(),
        pregnancyService.getActivePregnancy(),
        measurementService.getLatestMeasurements(),
        measurementService.getLatestRiskAssessment(),
        alertService.getUnreadAlerts(),
      ]);

      state = HomeData(
        patient: results[0] as Patient?,
        activePregnancy: results[1] as Pregnancy?,
        recentMeasurements: results[2] as List<Measurement>,
        latestRisk: results[3] as RiskAssessment?,
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
}

final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeData>(HomeNotifier.new);
