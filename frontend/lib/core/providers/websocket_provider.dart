import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahhty/data/services/websocket_service.dart';

final webSocketServiceProvider = ChangeNotifierProvider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);
  return service;
});
