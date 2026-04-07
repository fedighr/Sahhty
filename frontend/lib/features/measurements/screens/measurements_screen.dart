import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
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

  int? _getPatientId() => int.tryParse(ref.read(authProvider).patientId ?? '');

  String _emojiForType(String type) {
    switch (type) {
      case 'WEIGHT': return '⚖️';
      case 'BLOOD_PRESSURE': return '❤️';
      case 'GLYCEMIA': return '🩸';
      case 'TEMPERATURE': return '🌡️';
      case 'HEART_RATE': return '💓';
      case 'OXYGEN': return '🫁';
      default: return '📊';
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false, imageOpacity: 0),
          const FloatingParticles(particleCount: 10, maxOpacity: 0.1),
          _loading
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
                          const Text('📊', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          const Text('Aucune mesure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('Ajoutez votre première mesure', style: TextStyle(color: AppColors.textSecondary)),
                        ]).animate().fadeIn())
                      : RefreshIndicator(
                          onRefresh: _loadMeasurements,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _measurements.length,
                            itemBuilder: (context, i) {
                              final m = _measurements[i];
                              return _buildMeasurementCard(m, i);
                            },
                          ),
                        ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(dynamic m, int index) {
    final type = m['type'] ?? '';
    final value1 = m['value1'];
    final value2 = m['value2'];
    final unit = m['unit'] ?? '';
    final date = m['measurement_date'] ?? '';
    final ctxField = m['context'] ?? '';
    final color = _colorForType(type);

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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border(left: BorderSide(color: color.withAlpha(128), width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(_emojiForType(type), style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatType(type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(displayValue, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                if (ctxField.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(ctxField, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (60 * index).ms).slideX(begin: 0.06);
  }
}
