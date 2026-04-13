import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class EditMedicalScreen extends ConsumerStatefulWidget {
  const EditMedicalScreen({super.key});

  @override
  ConsumerState<EditMedicalScreen> createState() => _EditMedicalScreenState();
}

class _EditMedicalScreenState extends ConsumerState<EditMedicalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _doctorNameCtrl = TextEditingController();
  String? _selectedBloodType;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _chronicCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _doctorNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(patientServiceProvider).getPatientById(patientId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final p = result['patient'];
        _heightCtrl.text = '${p['height'] ?? ''}';
        _weightCtrl.text = '${p['weight'] ?? ''}';
        _selectedBloodType = p['blood_type'];
        _chronicCtrl.text = p['chronic_diseases'] ?? '';
        _allergiesCtrl.text = p['allergies'] ?? '';
        _medicationsCtrl.text = p['current_medications'] ?? '';
        _doctorNameCtrl.text = p['family_doctor_name'] ?? '';
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'height': int.tryParse(_heightCtrl.text.trim()) ?? 0,
      'weight': _weightCtrl.text.trim(),
      'blood_type': _selectedBloodType,
      'chronic_diseases': _chronicCtrl.text.trim(),
      'allergies': _allergiesCtrl.text.trim(),
      'current_medications': _medicationsCtrl.text.trim(),
      'family_doctor_name': _doctorNameCtrl.text.trim(),
    };

    final result = await ref.read(patientServiceProvider).updatePatient(patientId, data);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 8), Text('Informations médicales mises à jour !')]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Informations médicales', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _loadData, child: const Text('Réessayer')),
                    ]))
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: AppColors.accent.withAlpha(15), shape: BoxShape.circle),
                                  child: const Icon(Icons.medical_information_outlined, color: AppColors.accent, size: 48),
                                ),
                              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 24),
                              Center(child: const Text('Données médicales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 8),
                              Center(child: const Text('Modifiez vos informations de santé', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))).animate().fadeIn(delay: 150.ms),
                              const SizedBox(height: 32),

                              // Height & Weight side by side
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Taille (cm)'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _heightCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: '165',
                                            prefixIcon: Icon(Icons.height, color: AppColors.primary),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Requis';
                                            if (int.tryParse(v.trim()) == null) return 'Nombre';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Poids (kg)'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _weightCtrl,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            hintText: '65.5',
                                            prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Requis';
                                            if (double.tryParse(v.trim()) == null) return 'Nombre';
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Groupe sanguin'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedBloodType,
                                items: _bloodTypes.map((bt) => DropdownMenuItem(value: bt, child: Text(bt))).toList(),
                                onChanged: (v) => setState(() => _selectedBloodType = v),
                                decoration: const InputDecoration(
                                  hintText: 'Sélectionner',
                                  prefixIcon: Icon(Icons.bloodtype, color: AppColors.error),
                                ),
                              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Maladies chroniques'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _chronicCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Ex: Diabète, Hypertension...',
                                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 24), child: Icon(Icons.healing, color: AppColors.warning)),
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Allergies'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _allergiesCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Ex: Pénicilline, Arachides...',
                                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 24), child: Icon(Icons.warning_amber, color: AppColors.warning)),
                                ),
                              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Médicaments actuels'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _medicationsCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Médicaments que vous prenez actuellement...',
                                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 24), child: Icon(Icons.medication, color: AppColors.accent)),
                                ),
                              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Médecin traitant'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _doctorNameCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Nom du médecin',
                                  prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.info),
                                ),
                              ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.05),
                              const SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                  child: _saving
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [Icon(Icons.save_outlined), SizedBox(width: 8), Text('Enregistrer')],
                                        ),
                                ),
                              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary));
  }
}
