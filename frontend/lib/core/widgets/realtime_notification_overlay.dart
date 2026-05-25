import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/providers/websocket_provider.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/services/websocket_service.dart';

class RealtimeNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const RealtimeNotificationOverlay({super.key, required this.child});

  @override
  ConsumerState<RealtimeNotificationOverlay> createState() =>
      _RealtimeNotificationOverlayState();
}

class _RealtimeNotificationOverlayState
    extends ConsumerState<RealtimeNotificationOverlay> {
  StreamSubscription<WsNotification>? _sub;
  final List<_ToastEntry> _toasts = [];
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  void _startListening() {
    final wsService = ref.read(webSocketServiceProvider);
    _sub = wsService.notifications.listen(_showToast);
  }

  void _showToast(WsNotification notification) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _NotificationToast(
        notification: notification,
        onDismiss: () {
          entry.remove();
          _toasts.removeWhere((e) => e.entry == entry);
        },
      ),
    );

    _toasts.add(_ToastEntry(entry: entry));
    overlay.insert(entry);

    // Auto-remove after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
        _toasts.removeWhere((e) => e.entry == entry);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final t in _toasts) {
      if (t.entry.mounted) t.entry.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _ToastEntry {
  final OverlayEntry entry;
  _ToastEntry({required this.entry});
}

class _NotificationToast extends StatefulWidget {
  final WsNotification notification;
  final VoidCallback onDismiss;

  const _NotificationToast({
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    _progressController.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_dismissed) _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.notification.type) {
      case 'appointment_request':
      case 'appointment_confirmed':
        return AppColors.primary;
      case 'appointment_cancelled':
        return AppColors.error;
      case 'access_request':
        return AppColors.info;
      case 'access_granted':
        return AppColors.success;
      case 'risk_alert':
        return AppColors.riskHigh;
      case 'medication_reminder':
        return AppColors.warning;
      default:
        return AppColors.accent;
    }
  }

  IconData get _icon {
    switch (widget.notification.type) {
      case 'appointment_request':
      case 'appointment_confirmed':
        return Iconsax.calendar_tick;
      case 'appointment_cancelled':
        return Iconsax.calendar_remove;
      case 'access_request':
      case 'access_granted':
        return Iconsax.document_text;
      case 'risk_alert':
        return Iconsax.warning_2;
      case 'medication_reminder':
        return Iconsax.health;
      default:
        return Iconsax.notification;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;
    final safeTop = MediaQuery.of(context).padding.top;

    return Positioned(
      top: safeTop + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _dismiss,
          onHorizontalDragEnd: (d) {
            if (d.velocity.pixelsPerSecond.dx.abs() > 300) _dismiss();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar at top
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => LinearProgressIndicator(
                      value: 1 - _progressController.value,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 3,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.notification.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // Live dot
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                      .animate(onPlay: (c) => c.repeat())
                                      .fadeIn(duration: 500.ms)
                                      .then()
                                      .fadeOut(duration: 500.ms),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.notification.message,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Close
                        GestureDetector(
                          onTap: _dismiss,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .slideY(
                begin: -1.5,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),
        ),
      ),
    );
  }
}

/// Status indicator widget — shown in AppBar or wherever needed
class WsStatusIndicator extends ConsumerWidget {
  const WsStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(webSocketServiceProvider);
    final status = ws.status;

    Color color;
    String tooltip;
    switch (status) {
      case WsStatus.connected:
        color = AppColors.success;
        tooltip = 'Temps réel actif';
        break;
      case WsStatus.connecting:
        color = AppColors.warning;
        tooltip = 'Connexion...';
        break;
      case WsStatus.error:
        color = AppColors.error;
        tooltip = 'Connexion perdue';
        break;
      case WsStatus.disconnected:
        color = Colors.grey;
        tooltip = 'Hors ligne';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
          ],
        ),
      )
          .animate(
            onPlay: status == WsStatus.connecting
                ? (c) => c.repeat()
                : null,
          )
          .then(delay: 500.ms)
          .fadeIn(duration: 400.ms)
          .fadeOut(duration: 400.ms),
    );
  }
}
