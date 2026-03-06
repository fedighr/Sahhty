// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/primary_button.dart';
import '../widgets/snackbar_helper.dart';

enum _Gender { male, female }
enum _Role   { patient, doctor }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  final _firstFocus  = FocusNode();
  final _lastFocus   = FocusNode();
  final _emailFocus  = FocusNode();
  final _phoneFocus  = FocusNode();
  final _passFocus   = FocusNode();
  final _confirmFocus = FocusNode();

  DateTime? _birthDate;
  _Gender _gender = _Gender.male;
  _Role _role = _Role.patient;
  String _passValue = '';

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() => _passValue = _passCtrl.text));
  }

  @override
  void dispose() {
    for (final c in [_firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) c.dispose();
    for (final f in [_firstFocus, _lastFocus, _emailFocus, _phoneFocus, _passFocus, _confirmFocus]) f.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 1),
      locale: const Locale('fr'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(
          primary: AppColors.primary, onPrimary: Colors.white,
          surface: Colors.white, onSurface: AppColors.textPrimary,
        )),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_birthDate == null) {
      SnackbarHelper.showError(context, 'Veuillez sélectionner votre date de naissance');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Backend uses single-char codes
    final gender = _gender == _Gender.male ? AppConstants.genderMale : AppConstants.genderFemale;
    final role   = _role   == _Role.patient  ? AppConstants.rolePatient : AppConstants.roleDoctor;

    await ref.read(authNotifierProvider.notifier).signUp(
      firstName: _firstNameCtrl.text.trim(),
      lastName:  _lastNameCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim(),
      password:  _passCtrl.text,
      birthDate: DateFormat('yyyy-MM-dd').format(_birthDate!),
      gender:    gender,
      role:      role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthAwaitingVerification) {
        context.push(AppRoutes.verifyCode, extra: next.email);
      } else if (next is AuthError) {
        SnackbarHelper.showError(context, next.message);
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.inputBorder)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const AuthHeader(title: 'Créer un compte', subtitle: 'Rejoignez la communauté Sahhty', showLogo: false),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Informations personnelles', Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: AuthTextField(controller: _firstNameCtrl, label: 'Prénom', hint: 'Ahmed', prefixIcon: Icons.badge_outlined, validator: Validators.validateFirstName, focusNode: _firstFocus, nextFocusNode: _lastFocus, enabled: !isLoading)),
                      const SizedBox(width: 12),
                      Expanded(child: AuthTextField(controller: _lastNameCtrl, label: 'Nom', hint: 'Ben Ali', prefixIcon: Icons.badge_outlined, validator: Validators.validateLastName, focusNode: _lastFocus, nextFocusNode: _emailFocus, enabled: !isLoading)),
                    ]).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 14),
                    _buildDatePicker(isLoading).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 14),
                    _buildGenderSelector(isLoading).animate().fadeIn(delay: 180.ms),
                    const SizedBox(height: 24),
                    _sectionLabel('Informations du compte', Icons.account_circle_outlined),
                    const SizedBox(height: 12),
                    AuthTextField(controller: _emailCtrl, label: 'Email', hint: 'ahmed@exemple.tn', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: Validators.validateEmail, focusNode: _emailFocus, nextFocusNode: _phoneFocus, enabled: !isLoading).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 14),
                    AuthTextField(controller: _phoneCtrl, label: 'Téléphone', hint: '22345678', prefixIcon: Icons.phone_outlined, prefixText: '+216 ', keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: Validators.validatePhone, focusNode: _phoneFocus, nextFocusNode: _passFocus, enabled: !isLoading).animate().fadeIn(delay: 230.ms),
                    const SizedBox(height: 24),
                    _sectionLabel('Je suis...', Icons.medical_services_outlined),
                    const SizedBox(height: 12),
                    _buildRoleSelector(isLoading).animate().fadeIn(delay: 260.ms),
                    const SizedBox(height: 24),
                    _sectionLabel('Sécurité', Icons.security_outlined),
                    const SizedBox(height: 12),
                    PasswordTextField(controller: _passCtrl, focusNode: _passFocus, nextFocusNode: _confirmFocus, validator: Validators.validatePassword, enabled: !isLoading).animate().fadeIn(delay: 300.ms),
                    if (_passValue.isNotEmpty) PasswordStrengthIndicator(password: _passValue).animate().fadeIn(),
                    const SizedBox(height: 14),
                    PasswordTextField(controller: _confirmCtrl, label: 'Confirmer le mot de passe', focusNode: _confirmFocus, validator: (v) => Validators.validateConfirmPassword(v, _passCtrl.text), textInputAction: TextInputAction.done, enabled: !isLoading).animate().fadeIn(delay: 340.ms),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: 'Créer mon compte', onPressed: isLoading ? null : _submit, isLoading: isLoading, icon: Icons.person_add_rounded).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Déjà inscrit ? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                GestureDetector(onTap: () => context.pop(), child: const Text('Se connecter', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700))),
              ]).animate().fadeIn(delay: 440.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) => Row(children: [
    Icon(icon, size: 17, color: AppColors.primary),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
  ]);

  Widget _buildDatePicker(bool disabled) {
    final has = _birthDate != null;
    return GestureDetector(
      onTap: disabled ? null : _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: has ? AppColors.primary : AppColors.inputBorder, width: has ? 2 : 1.5),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 20, color: has ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(has ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'Date de naissance',
            style: TextStyle(fontSize: 14, color: has ? AppColors.textPrimary : AppColors.textHint, fontWeight: has ? FontWeight.w500 : FontWeight.w400))),
          const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  Widget _buildGenderSelector(bool disabled) => Row(children: [
    _genderOption(_Gender.male,   'Homme', Icons.male_rounded,   disabled),
    const SizedBox(width: 12),
    _genderOption(_Gender.female, 'Femme', Icons.female_rounded, disabled),
  ]);

  Widget _genderOption(_Gender g, String label, IconData icon, bool disabled) {
    final sel = _gender == g;
    return Expanded(child: GestureDetector(
      onTap: disabled ? null : () => setState(() => _gender = g),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.08) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : AppColors.inputBorder, width: sel ? 2 : 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: sel ? AppColors.primary : AppColors.textSecondary, size: 22),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: sel ? AppColors.primary : AppColors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
        ]),
      ),
    ));
  }

  Widget _buildRoleSelector(bool disabled) => Row(children: [
    _roleOption(_Role.patient, 'Patient', Icons.personal_injury_outlined, 'Suivi de ma santé', disabled),
    const SizedBox(width: 12),
    _roleOption(_Role.doctor,  'Médecin', Icons.local_hospital_outlined, 'Suivi de patients',  disabled),
  ]);

  Widget _roleOption(_Role r, String label, IconData icon, String sub, bool disabled) {
    final sel = _role == r;
    return Expanded(child: GestureDetector(
      onTap: disabled ? null : () => setState(() => _role = r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: sel ? LinearGradient(colors: [AppColors.primary.withOpacity(0.08), AppColors.accent.withOpacity(0.06)]) : null,
          color: sel ? null : AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : AppColors.inputBorder, width: sel ? 2 : 1.5),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? AppColors.primary : AppColors.textSecondary, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: sel ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: AppColors.textHint, fontSize: 10), textAlign: TextAlign.center),
          if (sel) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)), child: const Text('✓', style: TextStyle(color: Colors.white, fontSize: 10)))],
        ]),
      ),
    ));
  }
}
