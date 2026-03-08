// lib/features/auth/screens/verify_code_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/snackbar_helper.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isPasswordReset;
  const VerifyCodeScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendCountdown == 0) { t.cancel(); return; }
      setState(() => _resendCountdown--);
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-submit when all 6 digits entered
    if (_code.length == 6) _submit();
  }

  Future<void> _submit() async {
    if (_code.length < 6) {
      SnackbarHelper.showError(context, 'Entrez le code à 6 chiffres.');
      return;
    }
    final notifier = ref.read(authNotifierProvider.notifier);
    if (widget.isPasswordReset) {
      await notifier.verifyResetCode(email: widget.email, code: _code);
    } else {
      await notifier.verifyCode(email: widget.email, code: _code);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    await ref.read(authNotifierProvider.notifier).resendCode(email: widget.email);
    _startCountdown();
    if (mounted) SnackbarHelper.showSuccess(context, 'Code renvoyé sur ${widget.email}');
  }

  void _clearAndReset() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthVerified) {
        // Route directly to the correct setup screen based on saved role
        // No ProfileSelection screen needed — role was chosen at registration
        if (next.role == 'D') {
          context.go(AppRoutes.doctorSetup, extra: next.email);
        } else {
          context.go(AppRoutes.patientSetup, extra: next.email);
        }
      } else if (next is AuthCanResetPassword) {
        context.go(AppRoutes.forgotPassword,
            extra: {'email': widget.email, 'step': 'reset'});
      } else if (next is AuthError) {
        SnackbarHelper.showError(context, next.message);
        _clearAndReset();
        ref.read(authNotifierProvider.notifier).resetError();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    final maskedEmail = _maskEmail(widget.email);

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
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20, offset: const Offset(0, 8),
                  )],
                ),
                child: Icon(
                  widget.isPasswordReset
                      ? Icons.lock_reset_rounded
                      : Icons.mark_email_read_outlined,
                  color: Colors.white, size: 38,
                ),
              ).animate().scale(
                  begin: const Offset(0.3, 0.3), duration: 600.ms,
                  curve: Curves.elasticOut),

              const SizedBox(height: 28),

              Text(
                widget.isPasswordReset
                    ? 'Vérification réinitialisation'
                    : 'Vérifiez votre email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'Un code à 6 chiffres a été envoyé à\n'),
                    TextSpan(
                      text: maskedEmail,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) =>
                  _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    enabled: !isLoading,
                    onChanged: (v) => _onDigitEntered(i, v),
                    onBackspace: () {
                      if (_controllers[i].text.isEmpty && i > 0) {
                        _controllers[i - 1].clear();
                        _focusNodes[i - 1].requestFocus();
                      }
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 36),

              PrimaryButton(
                label: 'Vérifier',
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
                icon: Icons.verified_rounded,
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 28),

              // Resend
              _resendCountdown > 0
                ? Text(
                    'Renvoyer le code dans ${_resendCountdown}s',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ).animate().fadeIn()
                : GestureDetector(
                    onTap: _resend,
                    child: const Text(
                      'Renvoyer le code',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ).animate().fadeIn(),

              const SizedBox(height: 16),

              // Wrong email hint
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.textHint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Vérifiez vos spams si vous ne trouvez pas l\'email. '
                      'Le code expire dans 10 minutes.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                    ),
                  ),
                ]),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Masks email: ahmed@gmail.com → a***@g***.com
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local  = parts[0];
    final domain = parts[1].split('.');
    final maskedLocal  = local.length > 1  ? '${local[0]}***' : '***';
    final maskedDomain = domain.isNotEmpty ? '${domain[0][0]}***' : '***';
    final ext = domain.length > 1 ? '.${domain.last}' : '';
    return '$maskedLocal@$maskedDomain$ext';
  }
}

// ─── OTP digit box ────────────────────────────────────────────────────────────

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final hasValue  = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46, height: 58,
      decoration: BoxDecoration(
        color: hasValue
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasValue
              ? AppColors.primary
              : isFocused
                  ? AppColors.primary.withOpacity(0.6)
                  : AppColors.inputBorder,
          width: (isFocused || hasValue) ? 2 : 1.5,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.backspace) {
            widget.onBackspace();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) {
            setState(() {});
            widget.onChanged(v);
          },
        ),
      ),
    );
  }
}
