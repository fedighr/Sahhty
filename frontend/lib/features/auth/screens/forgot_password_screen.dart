// lib/features/auth/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/snackbar_helper.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // step: 'email' | 'reset'
  String _step = 'email';
  String _email = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    _email = _emailCtrl.text.trim();
    await ref.read(authNotifierProvider.notifier).startPasswordReset(email: _email);
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).resetPassword(
      email: _email,
      newPassword: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthAwaitingResetCode) {
        context.push(AppRoutes.verifyCode, extra: next.email);
      } else if (next is AuthPasswordReset) {
        SnackbarHelper.showSuccess(context, 'Mot de passe mis à jour !');
        context.go(AppRoutes.login);
      } else if (next is AuthCanResetPassword) {
        setState(() => _step = 'reset');
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
              color: AppColors.surface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 32),
                ).animate().scale(begin: const Offset(0.5,0.5), duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Text(
                  _step == 'email' ? 'Mot de passe oublié ?' : 'Nouveau mot de passe',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  _step == 'email'
                      ? 'Entrez votre email pour recevoir un code de réinitialisation.'
                      : 'Choisissez un nouveau mot de passe sécurisé.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 32),
                if (_step == 'email') ...[
                  AuthTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'nom@exemple.tn',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    enabled: !isLoading,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Envoyer le code',
                    onPressed: isLoading ? null : _submitEmail,
                    isLoading: isLoading,
                    icon: Icons.send_outlined,
                  ).animate().fadeIn(delay: 400.ms),
                ] else ...[
                  PasswordTextField(
                    controller: _passCtrl,
                    label: 'Nouveau mot de passe',
                    validator: Validators.validatePassword,
                    enabled: !isLoading,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 14),
                  PasswordTextField(
                    controller: _confirmCtrl,
                    label: 'Confirmer le mot de passe',
                    validator: (v) => Validators.validateConfirmPassword(v, _passCtrl.text),
                    textInputAction: TextInputAction.done,
                    enabled: !isLoading,
                  ).animate().fadeIn(delay: 380.ms),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Réinitialiser',
                    onPressed: isLoading ? null : _submitNewPassword,
                    isLoading: isLoading,
                    icon: Icons.lock_outline_rounded,
                  ).animate().fadeIn(delay: 460.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
