import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  List<dynamic> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() { _loading = true; _error = null; });
    final userId = ref.read(authProvider).userId;
    if (userId == null || userId.isEmpty) {
      setState(() { _loading = false; _error = 'ID utilisateur non trouvé'; });
      return;
    }
    final uid = int.tryParse(userId);
    if (uid == null) {
      setState(() { _loading = false; _error = 'ID utilisateur invalide'; });
      return;
    }

    final result = await ref.read(alertServiceProvider).getAlertsByUser(uid);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _alerts = result['alerts'] ?? [];
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  Future<void> _markAsRead(int alertId) async {
    await ref.read(alertServiceProvider).markAsRead(alertId);
    _loadAlerts();
  }

  IconData _iconForLevel(String level) {
    switch (level) {
      case 'CRITICAL': return Iconsax.warning_2;
      case 'WARNING': return Iconsax.warning_2;
      default: return Iconsax.info_circle;
    }
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'CRITICAL': return AppColors.riskHigh;
      case 'WARNING': return AppColors.riskMedium;
      default: return AppColors.info;
    }
  }

  String _formatType(String type) {
    switch (type) {
      case 'HEALTH': return 'Santé';
      case 'REMINDER': return 'Rappel';
      case 'DOCTOR_MESSAGE': return 'Message médecin';
      case 'SYSTEM': return 'Système';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false, imageOpacity: 0),
          const FloatingParticles(particleCount: 10, maxOpacity: 0.1),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Iconsax.close_circle, size: 48, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _loadAlerts, child: const Text('Réessayer')),
                    ]))
                  : _alerts.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Iconsax.notification, size: 64, color: AppColors.primary),
                            const SizedBox(height: 16),
                            const Text('Aucune alerte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Tout est en ordre !', style: TextStyle(color: AppColors.textSecondary)),
                          ]).animate().fadeIn(),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAlerts,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _alerts.length,
                            itemBuilder: (context, i) {
                              final alert = _alerts[i];
                              return _buildAlertCard(alert).animate().fadeIn(delay: (60 * i).ms).slideX(begin: 0.08);
                            },
                          ),
                        ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    final level = alert['level'] ?? 'INFO';
    final type = alert['type'] ?? '';
    final message = alert['message'] ?? '';
    final status = alert['status'] ?? '';
    final createdAt = alert['created_at'] ?? '';
    final id = alert['id'];
    final isRead = status == 'READ';
    final color = _colorForLevel(level);

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : color.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isRead ? const Color(0xFFE0E0E0) : color.withAlpha(64)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: !isRead && id != null ? () => _markAsRead(id) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(_iconForLevel(level), size: 22, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                          child: Text(_formatType(type), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        ),
                        const Spacer(),
                        Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 8),
                      Text('Appuyez pour marquer comme lu',
                          style: TextStyle(fontSize: 11, color: color.withAlpha(153), fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
