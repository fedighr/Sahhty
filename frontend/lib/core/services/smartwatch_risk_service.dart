import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Événement de risque déclenché par une mesure de la montre connectée.
class SmartWatchRiskEvent {
  final String riskLevel; // 'HIGH' ou 'MEDIUM'
  final String? note;
  final double? heartRate;
  final DateTime timestamp;

  SmartWatchRiskEvent({
    required this.riskLevel,
    this.note,
    this.heartRate,
  }) : timestamp = DateTime.now();
}

/// Service global qui diffuse les alertes de risque et les nouvelles mesures
/// de la montre, accessible depuis n'importe quelle page de l'app.
class SmartWatchRiskService {
  final _riskController = StreamController<SmartWatchRiskEvent>.broadcast();
  final _measurementController = StreamController<double>.broadcast();

  Stream<SmartWatchRiskEvent> get riskEvents => _riskController.stream;
  Stream<double> get newMeasurementEvents => _measurementController.stream;

  /// Déclenche une alerte de risque (seulement MEDIUM ou HIGH).
  void notifyRisk(String riskLevel, String? note, double? heartRate) {
    final level = riskLevel.toUpperCase();
    if (!_riskController.isClosed && level.isNotEmpty && level != 'LOW') {
      _riskController.add(SmartWatchRiskEvent(
        riskLevel: level,
        note: note,
        heartRate: heartRate,
      ));
    }
  }

  /// Notifie qu'une nouvelle mesure a été enregistrée (pour actualiser l'écran).
  void notifyNewMeasurement(double heartRate) {
    if (!_measurementController.isClosed) {
      _measurementController.add(heartRate);
    }
  }

  void dispose() {
    if (!_riskController.isClosed) _riskController.close();
    if (!_measurementController.isClosed) _measurementController.close();
  }
}

final smartWatchRiskServiceProvider = Provider<SmartWatchRiskService>((ref) {
  final service = SmartWatchRiskService();
  ref.onDispose(service.dispose);
  return service;
});
