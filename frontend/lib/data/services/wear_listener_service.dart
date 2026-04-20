import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/measurement_service.dart';

class WearListenerService {
  static const _channel = MethodChannel('com.example.sahhty/wear');
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final MeasurementService _measurementService;
  Function(String?, String?, double?)? onRiskAlert;

  WearListenerService({required MeasurementService measurementService})
      : _measurementService = measurementService;

  void start() {
    _channel.setMethodCallHandler(_handleMethod);
    _sendCredentialsToNative();
    debugPrint('[WearListener] Listening for watch data');
  }

  void stop() {
    _channel.setMethodCallHandler(null);
  }

  Future<void> _sendCredentialsToNative() async {
    try {
      final token = await _storage.read(key: StorageKeys.accessToken);
      final patientId = await _storage.read(key: StorageKeys.patientId);
      if (token != null && patientId != null) {
        await _channel.invokeMethod('setCredentials', {
          'token': token,
          'patient_id': patientId,
        });
        debugPrint('[WearListener] Credentials sent to native ✅');
      } else {
        debugPrint('[WearListener] No credentials found in storage');
      }
    } catch (e) {
      debugPrint('[WearListener] Failed to send credentials: $e');
    }
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {

      case 'onHeartRateFromWatch':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final heartRate = (data['heart_rate'] as num).toDouble();
        final context = data['context'] as String? ?? 'smartwatch data';

        debugPrint('[WearListener] Received HR from watch: $heartRate BPM');

        final patientIdStr = await _storage.read(key: StorageKeys.patientId);
        if (patientIdStr == null) {
          debugPrint('[WearListener] No patient ID stored, skipping POST');
          return;
        }

        final payload = {
          'type': 'HEART_RATE',
          'value1': heartRate.toStringAsFixed(2),
          'unit': 'BPM',
          'context': context,
          'patient_id': int.parse(patientIdStr),
        };

        debugPrint('[WearListener] Sending to backend: $payload');
        final result = await _measurementService.syncSmartwatch(payload: payload);
        debugPrint('[WearListener] Backend response: $result');
        break;

      case 'onRiskAlert':
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final riskLevel = data['risk_level'] as String?;
        final note = data['note'] as String?;
        final heartRate = (data['heart_rate'] as num?)?.toDouble();

        debugPrint('[WearListener] RISK ALERT: $riskLevel — $note');
        onRiskAlert?.call(riskLevel, note, heartRate);
        break;
    }
  }
}