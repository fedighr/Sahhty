// lib/features/profile_setup/screens/patient_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/auth_model.dart';
import '../../../features/auth/widgets/primary_button.dart';
import '../../../features/auth/widgets/snackbar_helper.dart';
import '../providers/profile_setup_notifier.dart';

class PatientSetupScreen extends ConsumerStatefulWidget {
  final String email;
  const PatientSetupScreen({super.key, required this.email});
  @override
  ConsumerState<PatientSetupScreen> createState() => _PatientSetupScreenState();
}

class _PatientSetupScreenState extends ConsumerState<PatientSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightCtrl  = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _allergiesCtrl    = TextEditingController();
  final _medicationsCtrl  = TextEditingController();
  final _familyDoctorCtrl = TextEditingController();

  String? _bloodType;
  String _menstrualStatus = 'ACTIVE';

  // Determine gender from parent — we show menstrual section for females
  // Since we don't pass gender here, we show it but keep it optional
  bool _showMenstrual = false;

  static const _bloodTypes = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];
  static const _menstrualStatuses = ['ACTIVE','MENOPAUSE','PREPUBESCENT'];

  @override
  void dispose() {
    for (final c in [_heightCtrl, _weightCtrl, _chronicCtrl, _allergiesCtrl, _medicationsCtrl, _familyDoctorCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final height = int.tryParse(_heightCtrl.text.trim()) ?? 0;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0;

    final request = CreatePatientRequest(
      email: widget.email,
      height: height,
      weight: weight,
      bloodType: _bloodType,
      chronicDiseases: _chronicCtrl.text.trim().isEmpty ? null : _chronicCtrl.text.trim(),
      allergies: _allergiesCtrl.text.trim().isEmpty ? null : _allergiesCtrl.text.trim(),
      currentMedications: _medicationsCtrl.text.trim().isEmpty ? null : _medicationsCtrl.text.trim(),
      familyDoctorName: _familyDoctorCtrl.text.trim().isEmpty ? null : _familyDoctorCtrl.text.trim(),
      menstrualCycle: _showMenstrual ? MenstrualCycleData(menstrualStatus: _menstrualStatus) : null,
    );

    await ref.read(profileSetupNotifierProvider.notifier).createPatient(request);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupNotifierProvider);
    final isLoading = state is ProfileSetupLoading;

    ref.listen<ProfileSetupState>(profileSetupNotifierProvider, (_, next) {
      if (next is ProfileSetupSuccess) {
        SnackbarHelper.showSuccess(context, 'Profil créé avec succès !');
        context.go(AppRoutes.patientHome);
      } else if (next is ProfileSetupError) {
        SnackbarHelper.showError(context, next.message);
        ref.read(profileSetupNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        title: const Text('Mon Profil Santé', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.inputBorder)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoCard(),
              const SizedBox(height: 24),
              _sectionLabel('Mesures corporelles', Icons.monitor_weight_outlined),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numField(_heightCtrl, 'Taille (cm)', 'ex: 175', Icons.height_rounded,
                    validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 50 || n > 250) return 'Entre 50-250 cm'; return null; })),
                const SizedBox(width: 12),
                Expanded(child: _numField(_weightCtrl, 'Poids (kg)', 'ex: 70', Icons.scale_outlined,
                    validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n < 1 || n > 500) return 'Poids invalide'; return null; }, decimal: true)),
              ]).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 14),
              _dropdownField().animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 24),
              _sectionLabel('Informations médicales', Icons.medical_information_outlined),
              const SizedBox(height: 12),
              _multilineField(_chronicCtrl, 'Maladies chroniques', 'Diabète, hypertension...', Icons.sick_outlined).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              _multilineField(_allergiesCtrl, 'Allergies', 'Pénicilline, arachides...', Icons.warning_amber_outlined).animate().fadeIn(delay: 230.ms),
              const SizedBox(height: 12),
              _multilineField(_medicationsCtrl, 'Médicaments actuels', 'Metformine 500mg...', Icons.medication_outlined).animate().fadeIn(delay: 260.ms),
              const SizedBox(height: 12),
              _textField(_familyDoctorCtrl, 'Médecin de famille', 'Dr. Ben Salah', Icons.person_outline_rounded,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !RegExp(r'^[a-zA-Z\s.]+$').hasMatch(v)) return 'Lettres uniquement';
                    return null;
                  }).animate().fadeIn(delay: 290.ms),
              const SizedBox(height: 24),
              // Menstrual section toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.inputBorder)),
                child: Row(children: [
                  const Icon(Icons.female_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Informations menstruelles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    const Text('Pour les patientes de sexe féminin', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ])),
                  Switch.adaptive(value: _showMenstrual, onChanged: (v) => setState(() => _showMenstrual = v), activeColor: AppColors.accent),
                ]),
              ).animate().fadeIn(delay: 320.ms),
              if (_showMenstrual) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Statut menstruel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ..._menstrualStatuses.map((s) => RadioListTile<String>(
                      value: s, groupValue: _menstrualStatus, dense: true,
                      onChanged: (v) => setState(() => _menstrualStatus = v!),
                      title: Text(_menstrualLabel(s), style: const TextStyle(fontSize: 14)),
                      activeColor: AppColors.accent,
                      contentPadding: EdgeInsets.zero,
                    )),
                  ]),
                ).animate().fadeIn(duration: 300.ms),
              ],
              const SizedBox(height: 32),
              PrimaryButton(label: 'Créer mon profil', onPressed: isLoading ? null : _submit, isLoading: isLoading, icon: Icons.check_circle_outline_rounded)
                  .animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              Center(child: TextButton(
                onPressed: () => context.go(AppRoutes.patientHome),
                child: const Text('Compléter plus tard', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
              )),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  String _menstrualLabel(String s) {
    switch (s) {
      case 'ACTIVE': return 'Active';
      case 'MENOPAUSE': return 'Ménopause';
      case 'PREPUBESCENT': return 'Prépubère';
      default: return s;
    }
  }

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text('Ces informations aident Sahhty à personnaliser vos recommandations de santé. Tout est sécurisé.',
          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
    ]),
  ).animate().fadeIn(duration: 400.ms);

  Widget _sectionLabel(String label, IconData icon) => Row(children: [
    Icon(icon, size: 17, color: AppColors.primary),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
  ]);

  Widget _numField(TextEditingController ctrl, String label, String hint, IconData icon,
      {String? Function(String?)? validator, bool decimal = false}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        inputFormatters: [decimal ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')) : FilteringTextInputFormatter.digitsOnly],
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true, fillColor: AppColors.inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _textField(TextEditingController ctrl, String label, String hint, IconData icon, {String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true, fillColor: AppColors.inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _multilineField(TextEditingController ctrl, String label, String hint, IconData icon) =>
      TextFormField(
        controller: ctrl,
        maxLines: 2, minLines: 1,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 16), child: Icon(icon, size: 20)),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          filled: true, fillColor: AppColors.inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _dropdownField() => DropdownButtonFormField<String>(
    value: _bloodType,
    hint: const Text('Groupe sanguin (optionnel)'),
    items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
    onChanged: (v) => setState(() => _bloodType = v),
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.bloodtype_outlined, size: 20),
      filled: true, fillColor: AppColors.inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
