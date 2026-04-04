import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/services/alert_service.dart';
import '../../../data/services/token_storage_service.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state_widget.dart';

final alertsProvider = FutureProvider<List<Alert>>((ref) async {
  final tokenStorage = ref.read(tokenStorageServiceProvider);
  final userId = await tokenStorage.getUserId();
  if (userId == null) return [];
  return ref.read(alertServiceProvider).getAlerts(userId);
});

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: alertsAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer(itemCount: 5)),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
              subtitle: 'Vos alertes et rappels apparaîtront ici.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            itemBuilder: (_, i) {
              final alert = alerts[i];
              return InkWell(
                onTap: () async {
                  if (alert.isNew && alert.id != null) {
                    await ref.read(alertServiceProvider).markAsRead(alert.id!);
                    ref.invalidate(alertsProvider);
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _alertBgColor(alert),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _alertColor(alert).withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _alertColor(alert).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_alertIcon(alert), color: _alertColor(alert), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Tag(label: alert.typeLabel, color: _alertColor(alert)),
                                const SizedBox(width: 8),
                                _Tag(label: alert.levelLabel, color: _alertColor(alert)),
                                const Spacer(),
                                if (alert.isNew)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: _alertColor(alert), shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(alert.message, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45)),
                            if (alert.createdAt != null) ...[
                              const SizedBox(height: 8),
                              Text(_formatDate(alert.createdAt!), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _alertColor(Alert alert) {
    if (alert.isCritical) return AppColors.error;
    if (alert.isWarning) return AppColors.warning;
    return AppColors.primary;
  }

  Color _alertBgColor(Alert alert) {
    if (alert.isCritical) return AppColors.errorLight;
    if (alert.isWarning) return const Color(0xFFFFF8E1);
    return const Color(0xFFEFF6FF);
  }

  IconData _alertIcon(Alert alert) {
    switch (alert.type) {
      case 'HEALTH':
        return Icons.monitor_heart_rounded;
      case 'REMINDER':
        return Icons.alarm_rounded;
      case 'DOCTOR_MESSAGE':
        return Icons.message_rounded;
      case 'SYSTEM':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatDate(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
