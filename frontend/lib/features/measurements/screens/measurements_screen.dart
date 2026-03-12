import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/services/measurement_service.dart';
import '../../../core/widgets/loading_shimmer.dart';

final measurementsProvider = FutureProvider<List<Measurement>>((ref) async {
  return ref.read(measurementServiceProvider).getMeasurements();
});

class MeasurementsScreen extends ConsumerWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measAsync = ref.watch(measurementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Mesures', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addMeasurement),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: measAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (measurements) {
          if (measurements.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monitor_heart_outlined, size: 64, color: AppColors.textHint.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('Aucune mesure enregistrée', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Ajoutez vos premières constantes', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                ],
              ),
            );
          }

          // Group by type
          final grouped = <String, List<Measurement>>{};
          for (final m in measurements) {
            grouped.putIfAbsent(m.type, () => []).add(m);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: grouped.entries.map((entry) {
              final latest = entry.value.first;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  border: latest.isAbnormal ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: _typeColor(latest.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_typeIcon(latest.type), color: _typeColor(latest.type), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(latest.typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('${latest.displayValue} ${latest.displayUnit}',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: latest.isAbnormal ? AppColors.error : AppColors.textPrimary)),
                              if (latest.isAbnormal) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                              ],
                            ],
                          ),
                          if (latest.measurementDate != null)
                            Text(
                              _formatDate(latest.measurementDate!),
                              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text('${entry.value.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const Text('mesures', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'BLOOD_PRESSURE': return const Color(0xFFE91E63);
      case 'WEIGHT': return const Color(0xFF00ACC1);
      case 'GLYCEMIA': return const Color(0xFF7C4DFF);
      case 'HEART_RATE': return const Color(0xFFFF7043);
      case 'TEMPERATURE': return const Color(0xFF26A69A);
      case 'OXYGEN': return const Color(0xFF1565C0);
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'BLOOD_PRESSURE': return Icons.favorite_rounded;
      case 'WEIGHT': return Icons.scale_rounded;
      case 'GLYCEMIA': return Icons.water_drop_rounded;
      case 'HEART_RATE': return Icons.monitor_heart_rounded;
      case 'TEMPERATURE': return Icons.thermostat_rounded;
      case 'OXYGEN': return Icons.air_rounded;
      default: return Icons.monitor_heart_outlined;
    }
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? "s" : ""}';
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return date;
    }
  }
}
