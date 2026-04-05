import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

/// Lists all measurements and allows viewing history.
class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  List<dynamic> _measurements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() { _loading = true; _error = null; });
    final patientId = _getPatientId();
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(measurementServiceProvider).getPatientMeasurements(patientId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _measurements = result['measurements'] ?? [];
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  int? _getPatientId() {
    final auth = ref.read(authProvider);
    return int.tryParse(auth.patientId ?? '');
  }

  String _formatType(String type) {
    switch (type) {
      case 'WEIGHT': return 'Poids';
      case 'BLOOD_PRESSURE': return 'Tension artérielle';
      case 'GLYCEMIA': return 'Glycémie';
      case 'TEMPERATURE': return 'Température';
      case 'HEART_RATE': return 'Rythme cardiaque';
      case 'OXYGEN': return 'Oxygène';
      default: return type;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'WEIGHT': return Icons.monitor_weight_outlined;
      case 'BLOOD_PRESSURE': return Icons.favorite_outline;
      case 'GLYCEMIA': return Icons.bloodtype_outlined;
      case 'TEMPERATURE': return Icons.thermostat_outlined;
      case 'HEART_RATE': return Icons.monitor_heart_outlined;
      case 'OXYGEN': return Icons.air;
      default: return Icons.analytics_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'WEIGHT': return AppColors.primary;
      case 'BLOOD_PRESSURE': return AppColors.error;
      case 'GLYCEMIA': return AppColors.info;
      case 'TEMPERATURE': return AppColors.warning;
      case 'HEART_RATE': return AppColors.primaryDark;
      case 'OXYGEN': return AppColors.accent;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes mesures')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-measurement');
          _loadMeasurements();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  TextButton(onPressed: _loadMeasurements, child: const Text('Réessayer')),
                ]))
              : _measurements.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.analytics_outlined, size: 64, color: AppColors.primary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('Aucune mesure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Ajoutez votre première mesure', style: TextStyle(color: AppColors.textSecondary)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadMeasurements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _measurements.length,
                        itemBuilder: (context, i) {
                          final m = _measurements[i];
                          final type = m['type'] ?? '';
                          final value1 = m['value1'];
                          final value2 = m['value2'];
                          final unit = m['unit'] ?? '';
                          final date = m['measurement_date'] ?? '';
                          final ctxField = m['context'] ?? '';

                          String displayValue = '$value1';
                          if (value2 != null) displayValue += '/$value2';
                          displayValue += ' $unit';

                          String dateStr = '';
                          if (date.isNotEmpty) {
                            final dt = DateTime.tryParse(date);
                            if (dt != null) {
                              dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: _colorForType(type).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_iconForType(type), color: _colorForType(type)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_formatType(type), style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(displayValue, style: TextStyle(color: _colorForType(type), fontWeight: FontWeight.bold)),
                                      if (ctxField.isNotEmpty)
                                        Text(ctxField, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
