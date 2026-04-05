import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

/// Add a new measurement.
/// Backend expects: {type, value1, value2?, unit, context?, patient_id}
class AddMeasurementScreen extends ConsumerStatefulWidget {
  const AddMeasurementScreen({super.key});

  @override
  ConsumerState<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends ConsumerState<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _value1Ctrl = TextEditingController();
  final _value2Ctrl = TextEditingController();
  final _contextCtrl = TextEditingController();
  String _selectedType = 'WEIGHT';
  bool _isLoading = false;

  static const _types = {
    'WEIGHT': {'label': 'Poids', 'unit': 'KG', 'icon': Icons.monitor_weight_outlined, 'hasValue2': false},
    'BLOOD_PRESSURE': {'label': 'Tension artérielle', 'unit': 'MMHG', 'icon': Icons.favorite_outline, 'hasValue2': true},
    'GLYCEMIA': {'label': 'Glycémie', 'unit': 'G_L', 'icon': Icons.bloodtype_outlined, 'hasValue2': false},
    'TEMPERATURE': {'label': 'Température', 'unit': 'C', 'icon': Icons.thermostat_outlined, 'hasValue2': false},
    'HEART_RATE': {'label': 'Rythme cardiaque', 'unit': 'BPM', 'icon': Icons.monitor_heart_outlined, 'hasValue2': false},
  };

  @override
  void dispose() {
    _value1Ctrl.dispose();
    _value2Ctrl.dispose();
    _contextCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final patientIdStr = ref.read(authProvider).patientId;
    final patientId = int.tryParse(patientIdStr ?? '');
    if (patientId == null) {
      _showError('ID patient non trouvé');
      return;
    }

    setState(() => _isLoading = true);

    final typeInfo = _types[_selectedType]!;
    final data = <String, dynamic>{
      'type': _selectedType,
      'value1': _value1Ctrl.text.trim(),
      'unit': typeInfo['unit'],
      'patient_id': patientId,
    };

    if (typeInfo['hasValue2'] == true && _value2Ctrl.text.isNotEmpty) {
      data['value2'] = _value2Ctrl.text.trim();
    }
    if (_contextCtrl.text.isNotEmpty) {
      data['context'] = _contextCtrl.text.trim();
    }

    final result = await ref.read(measurementServiceProvider).createMeasurement(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Check risk level from backend response
      final riskLevel = result['risk_level'] as String?;
      if (riskLevel != null && riskLevel != 'LOW') {
        _showRiskAlert(riskLevel);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesure enregistrée ✓'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } else {
      _showError(result['message'] ?? 'Erreur');
    }
  }

  void _showRiskAlert(String riskLevel) {
    final isHigh = riskLevel == 'HIGH';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isHigh ? Icons.dangerous_outlined : Icons.warning_amber_rounded,
              color: isHigh ? AppColors.riskHigh : AppColors.riskMedium,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isHigh ? 'Risque élevé !' : 'Attention',
              style: TextStyle(color: isHigh ? AppColors.riskHigh : AppColors.riskMedium, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isHigh ? AppColors.riskHigh : AppColors.riskMedium).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isHigh
                    ? 'Un risque élevé a été détecté. Veuillez consulter votre médecin immédiatement.'
                    : 'Un risque modéré a été détecté. Surveillez vos mesures de près.',
                style: TextStyle(color: isHigh ? AppColors.riskHigh : AppColors.riskMedium),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isHigh ? AppColors.riskHigh : AppColors.riskMedium,
            ),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo = _types[_selectedType]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle mesure'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type selector
                Text('Type de mesure', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.entries.map((e) {
                    final selected = e.key == _selectedType;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedType = e.key);
                        _value1Ctrl.clear();
                        _value2Ctrl.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(e.value['icon'] as IconData, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(e.value['label'] as String, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Value 1
                TextFormField(
                  controller: _value1Ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _selectedType == 'BLOOD_PRESSURE' ? 'Systolique' : 'Valeur',
                    prefixIcon: Icon(typeInfo['icon'] as IconData, color: AppColors.primary),
                    suffixText: typeInfo['unit'] as String,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Valeur requise';
                    if (double.tryParse(v) == null) return 'Nombre invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Value 2 (only for blood pressure)
                if (typeInfo['hasValue2'] == true) ...[
                  TextFormField(
                    controller: _value2Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Diastolique',
                      prefixIcon: Icon(Icons.favorite_outline, color: AppColors.primary),
                      suffixText: 'mmHg',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Valeur requise';
                      if (double.tryParse(v) == null) return 'Nombre invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Context
                TextFormField(
                  controller: _contextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contexte (optionnel)',
                    prefixIcon: Icon(Icons.note_outlined, color: AppColors.primary),
                    hintText: 'Ex: à jeun, après repas...',
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
