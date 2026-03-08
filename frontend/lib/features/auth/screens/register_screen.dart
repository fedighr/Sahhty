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
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/primary_button.dart';
import '../widgets/snackbar_helper.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────
enum _Gender { male, female }
enum _Role   { patient, doctor }

// ─── Main Screen ──────────────────────────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {

  // Steps: 0 = Profil, 1 = Compte, 2 = Rôle & Sécurité
  int _step = 0;
  static const int _totalSteps = 3;

  late final PageController _pageCtrl;
  late final AnimationController _stepAnim;

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  // FocusNodes
  final _firstFocus   = FocusNode();
  final _lastFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _phoneFocus   = FocusNode();
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();

  // Form keys per step
  final _formKey0 = GlobalKey<FormState>();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Values
  DateTime? _birthDate;
  _Gender _gender = _Gender.female;
  _Role   _role   = _Role.patient;
  String  _passValue = '';

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _stepAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _passCtrl.addListener(() => setState(() => _passValue = _passCtrl.text));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _stepAnim.dispose();
    for (final c in [_firstNameCtrl,_lastNameCtrl,_emailCtrl,_phoneCtrl,_passCtrl,_confirmCtrl]) c.dispose();
    for (final f in [_firstFocus,_lastFocus,_emailFocus,_phoneFocus,_passFocus,_confirmFocus]) f.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  Future<void> _next() async {
    FocusScope.of(context).unfocus();

    // Validate current step
    final valid = switch (_step) {
      0 => _validateStep0(),
      1 => _formKey1.currentState!.validate(),
      _ => true,
    };
    if (!valid) return;

    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      await _submit();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  bool _validateStep0() {
    if (_birthDate == null) {
      SnackbarHelper.showError(context, 'Veuillez sélectionner votre date de naissance');
      return false;
    }
    return _formKey0.currentState!.validate();
  }

  Future<void> _submit() async {
    if (!_formKey2.currentState!.validate()) return;

    final gender = _gender == _Gender.male ? AppConstants.genderMale : AppConstants.genderFemale;
    final role   = _role   == _Role.patient ? AppConstants.rolePatient : AppConstants.roleDoctor;

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

  // ── Date picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
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

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthAwaitingVerification) {
        // Passer l'email via extra — la route verifyCode le lit
        context.push(AppRoutes.verifyCode, extra: next.email);
      } else if (next is AuthError) {
        SnackbarHelper.showError(context, next.message);
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
          onPressed: isLoading ? null : _back,
        ),
        title: _StepIndicator(current: _step, total: _totalSteps),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Progress bar ─────────────────────────────────────────────────
            _AnimatedProgressBar(step: _step, total: _totalSteps),

            // ── Pages ────────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step0PersonalInfo(
                    formKey: _formKey0,
                    firstNameCtrl: _firstNameCtrl,
                    lastNameCtrl: _lastNameCtrl,
                    firstFocus: _firstFocus,
                    lastFocus: _lastFocus,
                    birthDate: _birthDate,
                    gender: _gender,
                    onPickDate: _pickDate,
                    onGenderChanged: (g) => setState(() => _gender = g),
                    isLoading: isLoading,
                  ),
                  _Step1AccountInfo(
                    formKey: _formKey1,
                    emailCtrl: _emailCtrl,
                    phoneCtrl: _phoneCtrl,
                    emailFocus: _emailFocus,
                    phoneFocus: _phoneFocus,
                    isLoading: isLoading,
                  ),
                  _Step2RoleAndPassword(
                    formKey: _formKey2,
                    passCtrl: _passCtrl,
                    confirmCtrl: _confirmCtrl,
                    passFocus: _passFocus,
                    confirmFocus: _confirmFocus,
                    passValue: _passValue,
                    role: _role,
                    onRoleChanged: (r) => setState(() => _role = r),
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _step < _totalSteps - 1 ? 'Continuer' : 'Créer mon compte',
                    icon:  _step < _totalSteps - 1 ? Icons.arrow_forward_rounded : Icons.person_add_rounded,
                    onPressed: isLoading ? null : _next,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Déjà inscrit ? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: isLoading ? null : () => context.pop(),
                      child: const Text('Se connecter',
                          style: TextStyle(color: AppColors.primary,
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 0 — Informations personnelles
// ─────────────────────────────────────────────────────────────────────────────
class _Step0PersonalInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final FocusNode firstFocus;
  final FocusNode lastFocus;
  final DateTime? birthDate;
  final _Gender gender;
  final VoidCallback onPickDate;
  final ValueChanged<_Gender> onGenderChanged;
  final bool isLoading;

  const _Step0PersonalInfo({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.firstFocus,
    required this.lastFocus,
    required this.birthDate,
    required this.gender,
    required this.onPickDate,
    required this.onGenderChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          _stepHeader(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Informations personnelles',
            subtitle: 'Dites-nous qui vous êtes',
          ),
          const SizedBox(height: 24),

          // Prénom / Nom
          Row(children: [
            Expanded(child: AuthTextField(
              controller: firstNameCtrl,
              label: 'Prénom', hint: 'Abdelhedi',
              prefixIcon: Icons.badge_outlined,
              validator: Validators.validateFirstName,
              focusNode: firstFocus, nextFocusNode: lastFocus,
              enabled: !isLoading,
            )),
            const SizedBox(width: 12),
            Expanded(child: AuthTextField(
              controller: lastNameCtrl,
              label: 'Nom', hint: 'Chakroun',
              prefixIcon: Icons.badge_outlined,
              validator: Validators.validateLastName,
              focusNode: lastFocus,
              enabled: !isLoading,
            )),
          ]).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),

          // Date naissance
          _DatePickerField(
            value: birthDate, onTap: isLoading ? null : onPickDate,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 14),

          // Genre
          _sectionLabel('Genre', Icons.wc_rounded),
          const SizedBox(height: 10),
          Row(children: [
            _GenderChip(
              selected: gender == _Gender.female,
              label: 'Femme', icon: Icons.female_rounded,
              onTap: isLoading ? null : () => onGenderChanged(_Gender.female),
            ),
            const SizedBox(width: 12),
            _GenderChip(
              selected: gender == _Gender.male,
              label: 'Homme', icon: Icons.male_rounded,
              onTap: isLoading ? null : () => onGenderChanged(_Gender.male),
            ),
          ]).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Informations du compte
// ─────────────────────────────────────────────────────────────────────────────
class _Step1AccountInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final FocusNode emailFocus;
  final FocusNode phoneFocus;
  final bool isLoading;

  const _Step1AccountInfo({
    required this.formKey,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.emailFocus,
    required this.phoneFocus,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          _stepHeader(
            context,
            icon: Icons.account_circle_outlined,
            title: 'Votre compte',
            subtitle: 'Vos identifiants de connexion',
          ),
          const SizedBox(height: 24),

          AuthTextField(
            controller: emailCtrl,
            label: 'Adresse email', hint: 'chakroun@exemple.tn',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            focusNode: emailFocus, nextFocusNode: phoneFocus,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),

          AuthTextField(
            controller: phoneCtrl,
            label: 'Numéro de téléphone', hint: '97370975',
            prefixIcon: Icons.phone_outlined,
            prefixText: '+216 ',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.validatePhone,
            focusNode: phoneFocus,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 16),

          // Info tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.security_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Votre email sera utilisé pour vérifier votre compte et récupérer votre mot de passe.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              )),
            ]),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Rôle + Sécurité (mot de passe)
// ─────────────────────────────────────────────────────────────────────────────
class _Step2RoleAndPassword extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final FocusNode passFocus;
  final FocusNode confirmFocus;
  final String passValue;
  final _Role role;
  final ValueChanged<_Role> onRoleChanged;
  final bool isLoading;

  const _Step2RoleAndPassword({
    required this.formKey,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.passFocus,
    required this.confirmFocus,
    required this.passValue,
    required this.role,
    required this.onRoleChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          _stepHeader(
            context,
            icon: Icons.medical_services_outlined,
            title: 'Votre profil Sahhty',
            subtitle: 'Choisissez votre type de compte',
          ),
          const SizedBox(height: 24),

          // ── Rôle ─────────────────────────────────────────────────────────
          _sectionLabel('Je suis...', Icons.person_pin_rounded),
          const SizedBox(height: 12),
          _RoleSelector(
            selected: role,
            onChanged: isLoading ? null : onRoleChanged,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 28),

          // ── Mot de passe ──────────────────────────────────────────────────
          _sectionLabel('Sécurité', Icons.lock_outline_rounded),
          const SizedBox(height: 12),

          PasswordTextField(
            controller: passCtrl,
            focusNode: passFocus,
            nextFocusNode: confirmFocus,
            validator: Validators.validatePassword,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 180.ms),

          if (passValue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PasswordStrengthIndicator(password: passValue),
            ).animate().fadeIn(),

          const SizedBox(height: 12),

          PasswordTextField(
            controller: confirmCtrl,
            label: 'Confirmer le mot de passe',
            focusNode: confirmFocus,
            validator: (v) => Validators.validateConfirmPassword(v, passCtrl.text),
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 240.ms),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets communs
// ─────────────────────────────────────────────────────────────────────────────

Widget _stepHeader(BuildContext context,
    {required IconData icon, required String title, required String subtitle}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withOpacity(0.25),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    ).animate().scale(begin: const Offset(0.6,0.6), duration: 400.ms, curve: Curves.elasticOut),
    const SizedBox(height: 14),
    Text(title,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800))
        .animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
    const SizedBox(height: 4),
    Text(subtitle,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14))
        .animate().fadeIn(delay: 180.ms),
  ]);
}

Widget _sectionLabel(String label, IconData icon) => Row(children: [
  Icon(icon, size: 16, color: AppColors.primary),
  const SizedBox(width: 6),
  Text(label, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
]);

// ─── Progress bar animée ──────────────────────────────────────────────────────
class _AnimatedProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const _AnimatedProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i <= step;
          final active = i == step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: active ? 6 : 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: filled ? AppColors.primary : AppColors.inputBorder,
                boxShadow: active ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 6,
                )] : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step indicator (1 / 3) ───────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        'Étape ${current + 1} sur $total',
        key: ValueKey(current),
        style: TextStyle(
          color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── Date picker field ────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback? onTap;
  const _DatePickerField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final has = value != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Date de naissance', Icons.calendar_today_outlined),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: has ? AppColors.primary : AppColors.inputBorder,
              width: has ? 2 : 1.5,
            ),
          ),
          child: Row(children: [
            Icon(Icons.calendar_month_outlined, size: 20,
                color: has ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(
              has ? DateFormat('dd MMMM yyyy', 'fr').format(value!) : 'Sélectionnez votre date',
              style: TextStyle(
                fontSize: 14,
                color: has ? AppColors.textPrimary : AppColors.textHint,
                fontWeight: has ? FontWeight.w500 : FontWeight.w400,
              ),
            )),
            Icon(Icons.arrow_drop_down_rounded,
                color: has ? AppColors.primary : AppColors.textSecondary),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Gender chip ──────────────────────────────────────────────────────────────
class _GenderChip extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _GenderChip({required this.selected, required this.label,
      required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.inputBorder,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          )),
        ]),
      ),
    ));
  }
}

// ─── Role selector ─────────────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final _Role selected;
  final ValueChanged<_Role>? onChanged;
  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _RoleCard(
        role: _Role.patient,
        selected: selected == _Role.patient,
        icon: Icons.personal_injury_outlined,
        title: 'Je suis Patient',
        description: 'Je souhaite suivre ma santé, consulter des médecins et recevoir des recommandations personnalisées.',
        badge: 'Suivi personnel',
        badgeIcon: Icons.favorite_rounded,
        gradient: AppColors.primaryGradient,
        onTap: onChanged == null ? null : () => onChanged!(_Role.patient),
      ),
      const SizedBox(height: 14),
      _RoleCard(
        role: _Role.doctor,
        selected: selected == _Role.doctor,
        icon: Icons.local_hospital_outlined,
        title: 'Je suis Médecin',
        description: 'Je souhaite gérer mes patients, suivre leurs dossiers médicaux et organiser mes consultations.',
        badge: 'Espace professionnel',
        badgeIcon: Icons.verified_rounded,
        gradient: const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF006064)]),
        onTap: onChanged == null ? null : () => onChanged!(_Role.doctor),
      ),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  final _Role role;
  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final IconData badgeIcon;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeIcon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = gradient.colors.first;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : AppColors.inputBorder,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected ? [BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 16, offset: const Offset(0, 4),
          )] : [BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: selected ? gradient : null,
              color: selected ? null : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon,
                color: selected ? Colors.white : color, size: 26),
          ),
          const SizedBox(width: 14),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title + checkmark
            Row(children: [
              Expanded(child: Text(title, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15,
                color: selected ? color : AppColors.textPrimary,
              ))),
              if (selected)
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ).animate().scale(begin: const Offset(0,0), duration: 250.ms, curve: Curves.elasticOut),
            ]),
            const SizedBox(height: 6),

            // Description
            Text(description, style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
            const SizedBox(height: 10),

            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(badgeIcon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(badge, style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }
}
