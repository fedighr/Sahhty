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
  const VerifyCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;
  bool _isResendMode; // true = verify_reset_code, false = verify_code
  bool get _isForgotFlow => _isResendMode;

  _VerifyCodeScreenState() : _isResendMode = false;

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
      if (_resendCountdown == 0) { t.cancel(); return; }
      setState(() => _resendCountdown--);
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _submit() async {
    if (_code.length < 6) {
      SnackbarHelper.showError(context, 'Entrez le code à 6 chiffres.');
      return;
    }
    final notifier = ref.read(authNotifierProvider.notifier);
    final currentState = ref.read(authNotifierProvider);

    if (currentState is AuthAwaitingResetCode) {
      await notifier.verifyResetCode(email: widget.email, code: _code);
    } else {
      await notifier.verifyCode(email: widget.email, code: _code);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    await ref.read(authNotifierProvider.notifier).resendCode(email: widget.email);
    _startCountdown();
    if (mounted) SnackbarHelper.showSuccess(context, 'Nouveau code envoyé!');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthVerified) {
        context.go(AppRoutes.profileSelection);
      } else if (next is AuthCanResetPassword) {
        context.go(AppRoutes.forgotPassword, extra: {'email': widget.email, 'step': 'reset'});
      } else if (next is AuthError) {
        SnackbarHelper.showError(context, next.message);
        for (final c in _controllers) c.clear();
        _focusNodes[0].requestFocus();
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 32),
              ).animate().scale(begin: const Offset(0.5,0.5), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text('Vérification Email', style: Theme.of(context).textTheme.headlineMedium)
                  .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'Un code à 6 chiffres a été envoyé à\n${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildDigitBox(i, isLoading)),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Vérifier',
                onPressed: isLoading ? null : _submit,
                isLoading: isLoading,
                icon: Icons.verified_outlined,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 20),
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Renvoyer le code dans $_resendCountdown s',
                        style: TextStyle(color: AppColors.textHint, fontSize: 13),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index, bool disabled) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: !disabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (v) => _onDigitEntered(index, v),
        onTap: () {
          _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length),
          );
        },
      ),
    );
  }
}
