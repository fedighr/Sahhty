// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/snackbar_helper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    _emailFocus.dispose(); _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthAuthenticated) {
        context.go(AppRoutes.patientHome);
      } else if (next is AuthError) {
        SnackbarHelper.showError(context, next.message);
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const AuthHeader(
                      title: 'Bienvenue',
                      subtitle: 'Connectez-vous à votre compte Sahhty',
                    ),
                    const SizedBox(height: 36),
                    Form(
                      key: _formKey,
                      child: Column(children: [
                        AuthTextField(
                          controller: _emailCtrl,
                          label: 'Email', hint: 'nom@exemple.tn',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          focusNode: _emailFocus, nextFocusNode: _passFocus,
                          enabled: !isLoading,
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 16),
                        PasswordTextField(
                          controller: _passCtrl, focusNode: _passFocus,
                          validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                          textInputAction: TextInputAction.done, enabled: !isLoading,
                        ).animate().fadeIn(delay: 380.ms).slideX(begin: 0.1, end: 0),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Se connecter', onPressed: isLoading ? null : _submit,
                      isLoading: isLoading, icon: Icons.login_rounded,
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: Divider(color: AppColors.divider, thickness: 1.5)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou', style: TextStyle(color: AppColors.textHint, fontSize: 13))),
                      Expanded(child: Divider(color: AppColors.divider, thickness: 1.5)),
                    ]).animate().fadeIn(delay: 560.ms),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: OutlinedButton(
                        onPressed: () => SnackbarHelper.showInfo(context, 'Bientôt disponible'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: AppColors.surface,
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                              child: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 18)),
                          const SizedBox(width: 10),
                          Text('Continuer avec Google', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                        ]),
                      ),
                    ).animate().fadeIn(delay: 620.ms),
                    const SizedBox(height: 32),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Pas encore de compte ? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: const Text('S\'inscrire', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ]).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
