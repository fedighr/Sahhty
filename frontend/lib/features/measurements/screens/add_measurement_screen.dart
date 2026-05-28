import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

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
    'WEIGHT': {'label': 'Poids', 'unit': 'KG', 'icon': Iconsax.weight, 'hasValue2': false},
    'BLOOD_PRESSURE': {'label': 'Tension artérielle', 'unit': 'MMHG', 'icon': Iconsax.heart, 'hasValue2': true},
    'GLYCEMIA': {'label': 'Glycémie', 'unit': 'G_L', 'icon': Iconsax.health, 'hasValue2': false},
    'TEMPERATURE': {'label': 'Température', 'unit': 'C', 'icon': Iconsax.health, 'hasValue2': false},
    'HEART_RATE': {'label': 'Rythme cardiaque', 'unit': 'BPM', 'icon': Iconsax.activity, 'hasValue2': false},
    'OXYGEN': {'label': 'Oxygène (SpO2)', 'unit': 'BPM', 'icon': Iconsax.activity, 'hasValue2': false},
  };

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? suffix,
    required Color color,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: color),
      suffixText: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1.5),
      ),
    );
  }

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
            Icon(Iconsax.warning_2,
                color: isHigh ? AppColors.riskHigh : AppColors.riskMedium, size: 28),
            const SizedBox(width: 8),
            Text(
              isHigh ? 'Risque élevé !' : 'Attention',
              style: TextStyle(
                  color: isHigh ? AppColors.riskHigh : AppColors.riskMedium,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isHigh ? AppColors.riskHigh : AppColors.riskMedium).withAlpha(25),
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
    final isMale = ref.watch(authProvider).gender == 'M';
    final themeColor = AppColors.patientColor(isMale);
    final bgColor = isMale ? Colors.white : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Nouvelle mesure'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: isMale
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD), Colors.white],
                  stops: [0.0, 0.35, 1.0],
                ),
              )
            : null,
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Type de mesure',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _types.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (context, index) {
                    final entry = _types.entries.elementAt(index);
                    final selected = entry.key == _selectedType;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedType = entry.key);
                        _value1Ctrl.clear();
                        _value2Ctrl.clear();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: selected ? themeColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? themeColor : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              entry.value['icon'] as IconData,
                              size: 18,
                              color: selected ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                entry.value['label'] as String,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 60,
                  child: TextFormField(
                    controller: _value1Ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(
                      label: _selectedType == 'BLOOD_PRESSURE' ? 'Systolique' : 'Valeur',
                      icon: typeInfo['icon'] as IconData,
                      suffix: typeInfo['unit'] as String,
                      color: themeColor,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Valeur requise';
                      if (double.tryParse(v) == null) return 'Nombre invalide';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                if (typeInfo['hasValue2'] == true) ...[
                  SizedBox(
                    height: 60,
                    child: TextFormField(
                      controller: _value2Ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        label: 'Diastolique',
                        icon: Iconsax.heart,
                        suffix: 'mmHg',
                        color: themeColor,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Valeur requise';
                        if (double.tryParse(v) == null) return 'Nombre invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  height: 60,
                  child: TextFormField(
                    controller: _contextCtrl,
                    decoration: _inputDecoration(
                      label: 'Contexte (optionnel)',
                      icon: Iconsax.note,
                      color: themeColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}