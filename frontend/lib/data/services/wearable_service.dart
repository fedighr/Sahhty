import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Status of the watch app detection.
enum WatchAppStatus {
  /// Watch app is installed and reachable.
  installed,
  /// Watch is paired but the app is not installed.
  notInstalled,
  /// No compatible watch detected.
  noWatch,
  /// An error occurred during detection.
  error,
}

class WearableCheckResult {
  final WatchAppStatus status;
  final String message;
  final String? watchNodeId;

  const WearableCheckResult({
    required this.status,
    required this.message,
    this.watchNodeId,
  });
}

/// Communicates with native Android code to detect and install
/// the Wear OS companion app on a paired smartwatch.
class WearableService {
  static const _channel = MethodChannel('com.sahhty/wearable');

  /// Check if a watch is paired and the Sahhty watch app is installed.
  static Future<WearableCheckResult> checkWatchApp() async {
    try {
      final result = await _channel.invokeMethod<Map>('checkWatchAppInstalled');
      if (result == null) {
        return const WearableCheckResult(
          status: WatchAppStatus.error,
          message: 'Pas de réponse du système.',
        );
      }

      final data = Map<String, dynamic>.from(result);
      final statusStr = data['status'] as String;
      final message = data['message'] as String? ?? '';

      switch (statusStr) {
        case 'installed':
          return WearableCheckResult(
            status: WatchAppStatus.installed,
            message: message,
          );
        case 'not_installed':
          return WearableCheckResult(
            status: WatchAppStatus.notInstalled,
            message: message,
            watchNodeId: data['watchNodeId'] as String?,
          );
        case 'no_watch':
          return WearableCheckResult(
            status: WatchAppStatus.noWatch,
            message: message,
          );
        default:
          return WearableCheckResult(
            status: WatchAppStatus.error,
            message: message,
          );
      }
    } on PlatformException catch (e) {
      debugPrint('[WearableService] PlatformException: ${e.message}');
      return WearableCheckResult(
        status: WatchAppStatus.error,
        message: e.message ?? 'Erreur inconnue.',
      );
    } catch (e) {
      debugPrint('[WearableService] Error: $e');
      return WearableCheckResult(
        status: WatchAppStatus.error,
        message: 'Erreur: $e',
      );
    }
  }

  /// Request the Play Store to open on the watch for installing the app.
  static Future<bool> triggerWatchAppInstall() async {
    try {
      final result = await _channel.invokeMethod<Map>('openPlayStoreOnWatch');
      if (result == null) return false;
      final data = Map<String, dynamic>.from(result);
      return data['status'] == 'sent';
    } on PlatformException catch (e) {
      debugPrint('[WearableService] Install error: ${e.message}');
      return false;
    }
  }
}
