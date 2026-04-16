import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:sahhty/data/services/health_connect_service.dart';
import 'package:sahhty/data/services/measurement_service.dart';

/// Result of a sync operation.
class SyncResult {
  final int sent;
  final List<Map<String, dynamic>> measurements; // returned by backend
  final List<String> errors;

  SyncResult({this.sent = 0, this.measurements = const [], this.errors = const []});

  bool get success => errors.isEmpty;
}

/// Syncs Health Connect data to the Django backend via a single bulk endpoint.
class VitalsSyncService {
  final HealthConnectService _healthConnect;
  final MeasurementService _measurementService;

  VitalsSyncService({
    required HealthConnectService healthConnect,
    required MeasurementService measurementService,
  })  : _healthConnect = healthConnect,
        _measurementService = measurementService;

  /// Fetch the latest heart rate from Health Connect and send it in one POST.
  Future<SyncResult> syncNow({required int patientId, int minutes = 120}) async {
    try {
      final points = await _healthConnect.fetchRecent(minutes: minutes);
      if (points.isEmpty) {
        return SyncResult(errors: ['Aucune donnée trouvée dans Health Connect']);
      }

      // Filter only heart rate and take the latest one
      final heartRatePoints = points
          .where((p) => p.type == HealthDataType.HEART_RATE)
          .toList();

      if (heartRatePoints.isEmpty) {
        return SyncResult(errors: ['Aucune mesure de rythme cardiaque trouvée']);
      }

      // Sort by date descending, take the latest
      heartRatePoints.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = heartRatePoints.first;

      double value;
      try {
        value = (latest.value as NumericHealthValue).numericValue.toDouble();
      } catch (_) {
        return SyncResult(errors: ['Impossible de lire la valeur du rythme cardiaque']);
      }

      final readings = [
        {
          'type': 'HEART_RATE',
          'value1': value.toStringAsFixed(2),
          'unit': 'BPM',
          'context': 'smartwatch data',
        }
      ];

      // Single POST to backend
      final result = await _measurementService.syncSmartwatch(
        patientId: patientId,
        readings: readings,
      );

      if (result['saved'] != null) {
        final measurements = (result['measurements'] as List?)
            ?.map((m) => Map<String, dynamic>.from(m))
            .toList() ?? [];
        return SyncResult(
          sent: result['saved'] as int,
          measurements: measurements,
        );
      } else {
        return SyncResult(errors: [result['message']?.toString() ?? 'Erreur inconnue']);
      }
    } catch (e) {
      debugPrint('[VitalsSync] Error: $e');
      return SyncResult(errors: [e.toString()]);
    }
  }
}
