import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';

class WearListenerService {
  static const _channel = MethodChannel('com.example.sahhty/wear');
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Appelé quand le backend détecte un risque non-LOW après une mesure montre.
  Function(String riskLevel, String? note, double? heartRate)? onRiskDetected;

  /// Appelé quand une nouvelle mesure arrive de la montre (pour rafraîchir l'UI).
  Function(double heartRate)? onNewMeasurement;

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
        // PhoneWearListenerService (Kotlin) a déjà envoyé la mesure au backend.
        // On notifie seulement l'UI qu'une nouvelle mesure est arrivée.
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final heartRate = (data['heart_rate'] as num).toDouble();
        debugPrint('[WearListener] Nouvelle FC reçue: $heartRate BPM (déjà sauvegardée par le service natif)');
        onNewMeasurement?.call(heartRate);
        break;

      case 'onRiskAlert':
        // Le service Kotlin a posté au backend et reçu le niveau de risque.
        // On notifie l'UI du risque et de la nouvelle mesure.
        final data = Map<String, dynamic>.from(call.arguments as Map);
        final riskLevel = (data['risk_level'] as String? ?? '').toUpperCase();
        final note = data['note'] as String?;
        final heartRate = (data['heart_rate'] as num?)?.toDouble();

        debugPrint('[WearListener] Alerte de risque: $riskLevel — $note');

        // Notifier la nouvelle mesure
        if (heartRate != null) onNewMeasurement?.call(heartRate);

        // Notifier le risque si ce n'est pas LOW
        if (riskLevel.isNotEmpty && riskLevel != 'LOW') {
          onRiskDetected?.call(riskLevel, note, heartRate);
        }
        break;
    }
  }
}