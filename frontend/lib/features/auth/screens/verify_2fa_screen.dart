import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sahhty/core/providers/websocket_provider.dart';

class Verify2FAScreen extends ConsumerStatefulWidget {
  final String email;
  const Verify2FAScreen({super.key, required this.email});

  @override
  ConsumerState<Verify2FAScreen> createState() => _Verify2FAScreenState();
}

class _Verify2FAScreenState extends ConsumerState<Verify2FAScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _errorMessage = 'Veuillez entrer le code complet');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await ref.read(authProvider.notifier).verify2FA(widget.email, _code);

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (auth.status == AuthStatus.authenticated) {
      // Register FCM device
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await ref.read(authServiceProvider).registerFcmDevice(token);
        }
      } catch (_) {}
      if (!mounted) return;
      // Connect WebSocket for real-time notifications
      ref.read(webSocketServiceProvider).connect();
      context.go(auth.role == 'D' ? '/doctor-home' : '/home');
    } else {
      setState(() {
        _errorMessage =
            result['message'] ?? 'Code invalide. Veuillez réessayer.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    final result =
        await ref.read(authServiceProvider).resendCode(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Code renvoyé'),
        backgroundColor:
            result['success'] == true ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-verify when all 6 digits entered
    if (_code.length == 6) {
      _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(showImage: true, imageOpacity: 0.08),
          const FloatingParticles(particleCount: 12, maxOpacity: 0.15),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(200),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Iconsax.arrow_left, size: 20),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 40),

                  // Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.15),
                            AppColors.primary.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5)
                        ],
                      ),
                      child: const Icon(Iconsax.shield_tick,
                          color: AppColors.primary, size: 48),
                    ),
                  )
                      .animate()
                      .scale(
                          delay: 100.ms,
                          duration: 500.ms,
                          curve: Curves.elasticOut),

                  const SizedBox(height: 28),
                  Text(
                    'Vérification en deux étapes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 12),
                  Text(
                    'Un code de vérification a été envoyé à\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary, height: 1.5),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  // OTP input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => _buildDigitBox(i)),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Error
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.close_circle,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().shake(),

                  const SizedBox(height: 32),

                  // Verify button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Vérifier',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 20),

                  // Resend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Vous n\'avez pas reçu le code ? ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: _isResending ? null : _resendCode,
                        child: _isResending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary))
                            : Text(
                                'Renvoyer',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withAlpha(230),
        ),
        onChanged: (v) => _onDigitChanged(index, v),
      ),
    );
  }
}
