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
  final _formKey   = GlobalKey<FormState>();
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
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthAuthenticated) {
        next.isDoctor
            ? context.go(AppRoutes.doctorHome)
            : context.go(AppRoutes.patientHome);
      } else if (next is AuthError) {
        SnackbarHelper.showError(context, next.message);
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    final authState   = ref.watch(authNotifierProvider);
    final isLoading   = authState is AuthLoading || authState is AuthSuccess;
    final isSuccess   = authState is AuthSuccess;
    final successData = isSuccess ? authState as AuthSuccess : null;

    return Stack(
      children: [
        Scaffold(
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
                              textInputAction: TextInputAction.done,
                              enabled: !isLoading,
                            ).animate().fadeIn(delay: 380.ms).slideX(begin: 0.1, end: 0),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : () => context.push(AppRoutes.forgotPassword),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Mot de passe oublié ?',
                                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Se connecter',
                          onPressed: isLoading ? null : _submit,
                          isLoading: authState is AuthLoading,
                          icon: Icons.login_rounded,
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        Row(children: [
                          Expanded(child: Divider(color: AppColors.divider, thickness: 1.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                          ),
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
                              Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                                child: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Continuer avec Google',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                            ]),
                          ),
                        ).animate().fadeIn(delay: 620.ms),
                        const SizedBox(height: 32),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text("Pas encore de compte ? ",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          GestureDetector(
                            onTap: isLoading ? null : () => context.push(AppRoutes.register),
                            child: const Text("S'inscrire",
                                style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
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
        ),

        // ── Success overlay ───────────────────────────────────────────────────
        if (isSuccess && successData != null)
          _SuccessOverlay(name: successData.name, isDoctor: successData.isDoctor),
      ],
    );
  }
}

// ─── Animated success overlay ─────────────────────────────────────────────────

class _SuccessOverlay extends StatelessWidget {
  final String name;
  final bool isDoctor;
  const _SuccessOverlay({required this.name, required this.isDoctor});

  @override
  Widget build(BuildContext context) {
    final firstName = name.isNotEmpty ? name.split(' ').first : 'vous';
    final greeting  = isDoctor ? 'Dr. $firstName' : firstName;
    final subtitle  = isDoctor
        ? 'Bienvenue sur votre espace médecin'
        : 'Bienvenue sur votre espace santé';

    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark circle
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 32, spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
            )
                .animate()
                .scale(
                    begin: const Offset(0, 0), end: const Offset(1, 1),
                    duration: 500.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 32),

            Text(
              'Bonjour, $greeting !',
              style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            )
                .animate(delay: 450.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 32),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isDoctor ? Icons.medical_services_rounded : Icons.favorite_rounded,
                  color: AppColors.primary, size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isDoctor ? 'Médecin' : 'Patient',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600, fontSize: 14,
                  ),
                ),
              ]),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

            const SizedBox(height: 40),

            // Pulsing dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                )
                    .animate(delay: Duration(milliseconds: 800 + i * 160))
                    .fadeIn(duration: 300.ms)
                    .then()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.5, duration: 500.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
