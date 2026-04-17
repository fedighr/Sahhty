import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

/// Service that reads health data from Health Connect (smartwatch data).
class HealthConnectService {
  final Health _health = Health();
  bool _configured = false;

  static const List<HealthDataType> supportedTypes = [
    HealthDataType.HEART_RATE,
  ];

  Future<void> _ensureConfigured() async {
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }
  }

  /// Request read permissions from Health Connect.
  /// Returns true if granted.
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      final granted = await _health.requestAuthorization(
        supportedTypes,
        permissions: supportedTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      debugPrint('[HealthConnect] Permissions granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('[HealthConnect] Permission error: $e');
      return false;
    }
  }

    /// Check if permissions are already granted.
  Future<bool> hasPermissions() async {
    try {
      await _ensureConfigured();
      final result = await _health.hasPermissions(
        supportedTypes,
        permissions: supportedTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      return result == true;
    } catch (e) {
      debugPrint('[HealthConnect] hasPermissions error: $e');
      return false;
    }
  }

  /// Check if Health Connect is available on this device.
  Future<bool> isAvailable() async {
    try {
      await _ensureConfigured();
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      debugPrint('[HealthConnect] Availability check error: $e');
      return false;
    }
  }

  /// Fetch health data points from the last [minutes] minutes.
  Future<List<HealthDataPoint>> fetchRecent({int minutes = 120}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(minutes: minutes));

    try {
      await _ensureConfigured();
      final data = await _health.getHealthDataFromTypes(
        startTime: since,
        endTime: now,
        types: supportedTypes,
      );
      // Remove duplicates manually (v13 removed Health.removeDuplicates)
      final seen = <String>{};
      final unique = data.where((p) {
        final key = '${p.type}_${p.dateFrom}_${p.value}';
        return seen.add(key);
      }).toList();
      debugPrint('[HealthConnect] Fetched ${unique.length} data points');
      return unique;
    } catch (e) {
      debugPrint('[HealthConnect] Fetch error: $e');
      return [];
    }
  }

  /// Convert a HealthDataPoint to a map suitable for creating a measurement.
  /// Maps Health Connect types to our backend measurement types.
  static Map<String, dynamic>? toMeasurementPayload(HealthDataPoint point, int patientId) {
    final mapping = _typeMapping[point.type];
    if (mapping == null) return null;

    double value;
    try {
      if (point.value is NumericHealthValue) {
        value = (point.value as NumericHealthValue).numericValue.toDouble();
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }

    return {
      'type': mapping['backendType'],
      'value1': value.toString(),
      'unit': mapping['unit'],
      'context': 'smartwatch data',
      'patient': patientId,
    };
  }

  static const Map<HealthDataType, Map<String, String>> _typeMapping = {
    HealthDataType.HEART_RATE: {'backendType': 'HEART_RATE', 'unit': 'BPM'},
  };
}
