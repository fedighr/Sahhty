// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

// ─── Local gender/role enum for UI ───────────────────────────────────────────

enum Gender { male, female }

enum UserRole { patient, doctor }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // State
  DateTime? _selectedBirthDate;
  Gender _selectedGender = Gender.male;
  UserRole _selectedRole = UserRole.patient;
  String _passwordValue = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordValue = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 1),
      locale: const Locale('fr'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // Manually validate birth date
    if (_selectedBirthDate == null) {
      SnackbarHelper.showError(
          context, 'Veuillez sélectionner votre date de naissance');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    final birthDateStr =
        DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);

    await ref.read(authNotifierProvider.notifier).signUp(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          birthDate: birthDateStr,
          gender: _selectedGender.name,
          role: _selectedRole.name,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    // Side effects
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go(AppRoutes.profileSelection);
      } else if (next is AuthError) {
        SnackbarHelper.showError(context, next.message);
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const AuthHeader(
                title: 'Créer un compte',
                subtitle: 'Rejoignez la communauté Sahhty',
                showLogo: false,
              ),
              const SizedBox(height: 28),
              _buildForm(isLoading),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Créer mon compte',
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
                icon: Icons.person_add_rounded,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 20),
              _buildLoginLink(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Personal Info Section ─────────────────────────────────────────
          _buildSectionLabel('Informations personnelles', Icons.person_outline_rounded),
          const SizedBox(height: 12),

          // First + Last name row
          Row(
            children: [
              Expanded(
                child: AuthTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  hint: 'Ahmed',
                  prefixIcon: Icons.badge_outlined,
                  validator: Validators.validateFirstName,
                  focusNode: _firstNameFocus,
                  nextFocusNode: _lastNameFocus,
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  hint: 'Ben Ali',
                  prefixIcon: Icons.badge_outlined,
                  validator: Validators.validateLastName,
                  focusNode: _lastNameFocus,
                  nextFocusNode: _emailFocus,
                  enabled: !isLoading,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 14),

          // Birth date picker
          _buildDatePicker(isLoading)
              .animate()
              .fadeIn(delay: 150.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 14),

          // Gender selector
          _buildGenderSelector(isLoading)
              .animate()
              .fadeIn(delay: 180.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // ── Account Info Section ──────────────────────────────────────────
          _buildSectionLabel('Informations du compte', Icons.account_circle_outlined),
          const SizedBox(height: 12),

          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'ahmed@exemple.tn',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            focusNode: _emailFocus,
            nextFocusNode: _phoneFocus,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 14),

          AuthTextField(
            controller: _phoneController,
            label: 'Téléphone',
            hint: '22 345 678',
            prefixIcon: Icons.phone_outlined,
            prefixText: '+216 ',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.validatePhone,
            focusNode: _phoneFocus,
            nextFocusNode: _passwordFocus,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // ── Role Section ──────────────────────────────────────────────────
          _buildSectionLabel('Je suis...', Icons.medical_services_outlined),
          const SizedBox(height: 12),

          _buildRoleSelector(isLoading)
              .animate()
              .fadeIn(delay: 260.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // ── Security Section ──────────────────────────────────────────────
          _buildSectionLabel('Sécurité', Icons.security_outlined),
          const SizedBox(height: 12),

          PasswordTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '••••••••',
            focusNode: _passwordFocus,
            nextFocusNode: _confirmPasswordFocus,
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

          // Password strength
          if (_passwordValue.isNotEmpty)
            PasswordStrengthIndicator(password: _passwordValue)
                .animate()
                .fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          PasswordTextField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            focusNode: _confirmPasswordFocus,
            validator: (val) =>
                Validators.validateConfirmPassword(val, _passwordController.text),
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
          ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isLoading) {
    final hasDate = _selectedBirthDate != null;
    return GestureDetector(
      onTap: isLoading ? null : _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDate ? AppColors.primary : AppColors.inputBorder,
            width: hasDate ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: hasDate ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDate
                    ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                    : 'Date de naissance',
                style: TextStyle(
                  fontSize: 14,
                  color: hasDate ? AppColors.textPrimary : AppColors.textHint,
                  fontWeight:
                      hasDate ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector(bool isLoading) {
    return Row(
      children: [
        _buildGenderOption(Gender.male, 'Homme', Icons.male_rounded, isLoading),
        const SizedBox(width: 12),
        _buildGenderOption(Gender.female, 'Femme', Icons.female_rounded, isLoading),
      ],
    );
  }

  Widget _buildGenderOption(
      Gender gender, String label, IconData icon, bool isLoading) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => setState(() => _selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.inputBorder,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(bool isLoading) {
    return Row(
      children: [
        _buildRoleOption(
          UserRole.patient,
          'Patient',
          Icons.personal_injury_outlined,
          'Suivi de ma santé',
          isLoading,
        ),
        const SizedBox(width: 12),
        _buildRoleOption(
          UserRole.doctor,
          'Médecin',
          Icons.local_hospital_outlined,
          'Suivi de patients',
          isLoading,
        ),
      ],
    );
  }

  Widget _buildRoleOption(
    UserRole role,
    String label,
    IconData icon,
    String subtitle,
    bool isLoading,
  ) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.accent.withOpacity(0.06),
                    ],
                  )
                : null,
            color: isSelected ? null : AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.inputBorder,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '✓',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Déjà inscrit ? ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Se connecter',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}
