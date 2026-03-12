import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/services/measurement_service.dart';

class AddMeasurementScreen extends ConsumerStatefulWidget {
  const AddMeasurementScreen({super.key});

  @override
  ConsumerState<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends ConsumerState<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'BLOOD_PRESSURE';
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();
  final _contextController = TextEditingController();
  bool _isLoading = false;

  static const _types = [
    ('BLOOD_PRESSURE', 'Tension artérielle', 'MMHG', true),
    ('WEIGHT', 'Poids', 'KG', false),
    ('GLYCEMIA', 'Glycémie', 'G_L', false),
    ('HEART_RATE', 'Fréquence cardiaque', 'BPM', false),
    ('TEMPERATURE', 'Température', 'C', false),
  ];

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentType = _types.firstWhere((t) => t.$1 == _selectedType);
    final hasValue2 = currentType.$4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle mesure', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type de mesure', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) => ChoiceChip(
                  label: Text(t.$2),
                  selected: _selectedType == t.$1,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = t.$1;
                        _value1Controller.clear();
                        _value2Controller.clear();
                      });
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _selectedType == t.$1 ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: _selectedType == t.$1 ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),

              if (hasValue2) ...[
                const Text('Systolique (haute)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _value1Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'ex: 120', suffixText: 'mmHg'),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                const Text('Diastolique (basse)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _value2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'ex: 80', suffixText: 'mmHg'),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
              ] else ...[
                Text('Valeur (${currentType.$2})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _value1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(hintText: 'Saisir la valeur', suffixText: _unitLabel(currentType.$3)),
                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                ),
              ],

              const SizedBox(height: 16),
              const Text('Contexte (optionnel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contextController,
                decoration: const InputDecoration(hintText: 'ex: À jeun, après effort...'),
                maxLines: 2,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _unitLabel(String unit) {
    switch (unit) {
      case 'KG': return 'kg';
      case 'MMHG': return 'mmHg';
      case 'G_L': return 'g/L';
      case 'C': return '°C';
      case 'BPM': return 'bpm';
      default: return unit;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final currentType = _types.firstWhere((t) => t.$1 == _selectedType);

    final measurement = Measurement(
      type: _selectedType,
      value1: double.tryParse(_value1Controller.text) ?? 0,
      value2: currentType.$4 ? double.tryParse(_value2Controller.text) : null,
      unit: currentType.$3,
      context: _contextController.text.isNotEmpty ? _contextController.text : null,
    );

    try {
      final result = await ref.read(measurementServiceProvider).createMeasurement(measurement);
      if (mounted) {
        final riskLevel = result['risk_level'] as String?;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(riskLevel != null ? 'Mesure enregistrée — Risque: $riskLevel' : 'Mesure enregistrée avec succès'),
            backgroundColor: riskLevel == 'HIGH' ? AppColors.error : AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
