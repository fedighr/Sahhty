import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sahhty/data/services/measurement_service.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Listens for heart rate data pushed from the paired Wear OS watch
/// via the native MethodChannel and POSTs it to the Django backend.
class WearListenerService {
  static const _channel = MethodChannel('com.example.sahhty/wear');
  static const _storage = FlutterSecureStorage();

  final MeasurementService _measurementService;

  WearListenerService({required MeasurementService measurementService})
      : _measurementService = measurementService;

  /// Call once at app startup (e.g. in main or after login).
  void start() {
    _channel.setMethodCallHandler(_handleMethod);
    debugPrint('[WearListener] Listening for watch heart rate data');
  }

  void stop() {
    _channel.setMethodCallHandler(null);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == 'onHeartRateFromWatch') {
      final data = Map<String, dynamic>.from(call.arguments as Map);
      final heartRate = (data['heart_rate'] as num).toDouble();
      final context = data['context'] as String? ?? 'smartwatch data';

      debugPrint('[WearListener] Received HR from watch: $heartRate BPM');

      // Read patient ID from secure storage
      final patientIdStr = await _storage.read(key: StorageKeys.patientId);
      if (patientIdStr == null) {
        debugPrint('[WearListener] No patient ID stored, skipping POST');
        return;
      }
      final patientId = int.parse(patientIdStr);

      final payload = {
        'type': 'HEART_RATE',
        'value1': heartRate.toStringAsFixed(2),
        'unit': 'BPM',
        'context': context,
        'patient': patientId,
      };

      debugPrint('[WearListener] Sending to backend: $payload');
      final result = await _measurementService.syncSmartwatch(payload: payload);
      debugPrint('[WearListener] Backend response: $result');
    }
  }
}
