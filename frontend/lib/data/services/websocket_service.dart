import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';

enum WsStatus { disconnected, connecting, connected, error }

class WsNotification {
  final String type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  WsNotification({
    required this.type,
    required this.data,
  }) : receivedAt = DateTime.now();

  String get title {
    switch (type) {
      case 'appointment_request':
        return 'Nouvelle demande de RDV';
      case 'appointment_confirmed':
        return 'Rendez-vous confirmé';
      case 'appointment_cancelled':
        return 'Rendez-vous annulé';
      case 'access_request':
        return "Demande d'accès médical";
      case 'access_granted':
        return 'Accès accordé';
      case 'risk_alert':
        return '⚠️ Alerte de risque';
      case 'medication_reminder':
        return '💊 Rappel médicament';
      default:
        return 'Notification';
    }
  }

  String get message {
    switch (type) {
      case 'appointment_request':
        final patient = data['patient_name'] ?? 'Un patient';
        return '$patient a demandé un rendez-vous';
      case 'appointment_confirmed':
        return 'Votre rendez-vous a été confirmé';
      case 'appointment_cancelled':
        return 'Votre rendez-vous a été annulé';
      case 'access_request':
        final doc = data['doctor_name'] ?? 'Un médecin';
        final spec = data['specialty'] ?? '';
        return 'Dr. $doc ($spec) demande accès à votre dossier';
      case 'access_granted':
        final patient = data['patient_name'] ?? 'Un patient';
        return '$patient a accepté votre demande d\'accès';
      case 'risk_alert':
        final level = data['risk_level'] ?? '';
        return 'Niveau de risque: $level';
      default:
        return data['message']?.toString() ?? 'Vous avez une nouvelle notification';
    }
  }
}

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  WsStatus _status = WsStatus.disconnected;
  final _notificationController = StreamController<WsNotification>.broadcast();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  WsStatus get status => _status;
  Stream<WsNotification> get notifications => _notificationController.stream;
  bool get isConnected => _status == WsStatus.connected;

  Future<void> connect() async {
    if (_status == WsStatus.connecting || _status == WsStatus.connected) return;

    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      debugPrint('[WS] No token — skipping WebSocket connection');
      return;
    }

    _setStatus(WsStatus.connecting);

    try {
      final baseUrl = ApiEndpoints.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      final uri = Uri.parse('$baseUrl/ws/notifications/?token=$token');
      debugPrint('[WS] Connecting to $uri');

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _setStatus(WsStatus.connected);
      _reconnectAttempts = 0;
      debugPrint('[WS] Connected ✓');
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _setStatus(WsStatus.error);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? 'unknown';
      final payload = data['data'] as Map<String, dynamic>? ?? data;
      final notification = WsNotification(type: type, data: payload);
      debugPrint('[WS] Received: $type');
      _notificationController.add(notification);
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[WS] Error: $error');
    _setStatus(WsStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    if (_status != WsStatus.disconnected) {
      _setStatus(WsStatus.error);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WS] Max reconnect attempts reached');
      return;
    }
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _reconnectAttempts++;
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  void _setStatus(WsStatus s) {
    _status = s;
    notifyListeners();
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setStatus(WsStatus.disconnected);
    _reconnectAttempts = 0;
    debugPrint('[WS] Disconnected');
  }

  @override
  void dispose() {
    disconnect();
    _notificationController.close();
    super.dispose();
  }
}
