// lib/features/profile_setup/screens/doctor_setup_screen.dart

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

class DoctorSetupScreen extends ConsumerStatefulWidget {
  final String email;
  const DoctorSetupScreen({super.key, required this.email});
  @override
  ConsumerState<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends ConsumerState<DoctorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl     = TextEditingController();
  final _experienceCtrl  = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _bioCtrl         = TextEditingController();

  // userId would come from decoded JWT in production
  // For now we prompt for it — in final version decode from token
  final _userIdCtrl      = TextEditingController();
  final _specialityIdCtrl = TextEditingController();

  String _ville = 'TUNIS';

  static const _villes = [
    ('TUNIS','Tunis'),('ARIANA','Ariana'),('BEN_AROUS','Ben Arous'),
    ('MANOUBA','Manouba'),('NABEUL','Nabeul'),('ZAGHOUAN','Zaghouan'),
    ('BIZERTE','Bizerte'),('BEJA','Béja'),('JENDOUBA','Jendouba'),
    ('KEF','Le Kef'),('SILIANA','Siliana'),('SOUSSE','Sousse'),
    ('MONASTIR','Monastir'),('MAHDIA','Mahdia'),('SFAX','Sfax'),
    ('KAIROUAN','Kairouan'),('KASSERINE','Kasserine'),('SIDI_BOUZID','Sidi Bouzid'),
    ('GABES','Gabès'),('MEDENINE','Médenine'),('TATAOUINE','Tataouine'),
    ('GAFSA','Gafsa'),('TOZEUR','Tozeur'),('KEBILI','Kébili'),
  ];

  @override
  void dispose() {
    for (final c in [_addressCtrl,_experienceCtrl,_priceCtrl,_bioCtrl,_userIdCtrl,_specialityIdCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final request = CreateDoctorRequest(
      userId: int.parse(_userIdCtrl.text.trim()),
      specialityId: int.parse(_specialityIdCtrl.text.trim()),
      ville: _ville,
      address: _addressCtrl.text.trim(),
      experience: int.parse(_experienceCtrl.text.trim()),
      consultationPrice: _priceCtrl.text.trim().isEmpty ? null : double.tryParse(_priceCtrl.text.trim()),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    );
    await ref.read(profileSetupNotifierProvider.notifier).createDoctor(request);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupNotifierProvider);
    final isLoading = state is ProfileSetupLoading;

    ref.listen<ProfileSetupState>(profileSetupNotifierProvider, (_, next) {
      if (next is ProfileSetupSuccess) {
        SnackbarHelper.showSuccess(context, 'Profil médecin créé !');
        context.go(AppRoutes.doctorHome);
      } else if (next is ProfileSetupError) {
        SnackbarHelper.showError(context, next.message);
        ref.read(profileSetupNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        title: const Text('Profil Médecin', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.inputBorder)),
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
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF006064)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(children: [
                  Icon(Icons.local_hospital_outlined, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(child: Text('Renseignez vos informations professionnelles pour que les patients puissent vous trouver.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
                ]),
              ).animate().fadeIn(),
              const SizedBox(height: 24),
              _section('Identifiants', Icons.badge_outlined),
              const SizedBox(height: 12),
              _numField(_userIdCtrl, 'ID Utilisateur', 'Votre ID user', Icons.person_outline_rounded,
                  validator: (v) { if (int.tryParse(v ?? '') == null) return 'ID invalide'; return null; }).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 12),
              _numField(_specialityIdCtrl, 'ID Spécialité', 'ID de votre spécialité', Icons.medical_services_outlined,
                  validator: (v) { if (int.tryParse(v ?? '') == null) return 'ID invalide'; return null; }).animate().fadeIn(delay: 110.ms),
              const SizedBox(height: 24),
              _section('Localisation', Icons.location_on_outlined),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _ville,
                items: _villes.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
                onChanged: (v) => setState(() => _ville = v!),
                decoration: _inputDeco('Ville', 'Sélectionnez une ville', icon: Icons.location_city_outlined),
              ).animate().fadeIn(delay: 140.ms),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2, minLines: 1,
                validator: (v) { if (v == null || v.trim().isEmpty) return 'Adresse requise'; return null; },
                decoration: _inputDeco('Adresse du cabinet', '15 Rue Ibn Khaldoun, Tunis', icon: Icons.home_work_outlined),
              ).animate().fadeIn(delay: 170.ms),
              const SizedBox(height: 24),
              _section('Expérience professionnelle', Icons.work_history_outlined),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numField(_experienceCtrl, 'Années d\'expérience', 'ex: 10', Icons.timeline_outlined,
                    validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 0) return 'Valeur invalide'; return null; })),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _inputDeco('Prix consultation (TND)', 'ex: 50', icon: Icons.payments_outlined),
                )),
              ]).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              _section('Biographie', Icons.description_outlined),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 4, minLines: 2,
                decoration: _inputDeco('Présentation (optionnel)', 'Spécialiste en gynécologie obstétrique avec 10 ans d\'expérience...', icon: Icons.edit_note_rounded),
              ).animate().fadeIn(delay: 230.ms),
              const SizedBox(height: 32),
              PrimaryButton(label: 'Créer mon profil', onPressed: isLoading ? null : _submit, isLoading: isLoading, icon: Icons.check_circle_outline_rounded)
                  .animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              Center(child: TextButton(
                onPressed: () => context.go(AppRoutes.doctorHome),
                child: const Text('Compléter plus tard', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
              )),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _section(String label, IconData icon) => Row(children: [
    Icon(icon, size: 17, color: AppColors.primary),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
  ]);

  Widget _numField(TextEditingController ctrl, String label, String hint, IconData icon, {String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _inputDeco(label, hint, icon: icon),
      );

  InputDecoration _inputDeco(String label, String hint, {IconData? icon}) => InputDecoration(
    labelText: label, hintText: hint,
    prefixIcon: icon != null ? Icon(icon, size: 20) : null,
    filled: true, fillColor: AppColors.inputFill,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.inputBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
