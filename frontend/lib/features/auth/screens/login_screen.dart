import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (auth.status == AuthStatus.authenticated) {
      // Register FCM device after successful login
      _registerFcmDevice();
      // Redirect based on role
      context.go(auth.role == 'D' ? '/doctor-home' : '/home');
    } else if (auth.status == AuthStatus.needsVerification) {
      context.push('/verify', extra: _emailController.text.trim());
    } else if (auth.status == AuthStatus.needsProfileSetup) {
      // Read pending info to know if this is a doctor or patient setup
      final pendingInfo = await ref.read(authServiceProvider).getPendingSetupInfo();
      if (!mounted) return;
      final role = pendingInfo['role'] ?? 'P';
      final gender = pendingInfo['gender'] ?? 'F';
      if (role == 'D') {
        context.push('/doctor-setup', extra: {
          'email': _emailController.text.trim(),
          'userId': pendingInfo['userId'] ?? '',
        });
      } else {
        context.push('/patient-setup', extra: {
          'email': _emailController.text.trim(),
          'gender': gender,
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Erreur de connexion'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _registerFcmDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(authServiceProvider).registerFcmDevice(token);
      }
    } catch (e) {
      debugPrint('FCM registration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background with image
          const AnimatedBackground(showImage: true, imageOpacity: 0.10),
          // Floating particles
          const FloatingParticles(particleCount: 12, maxOpacity: 0.15),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Logo & Title with animations
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withAlpha(77), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(Iconsax.heart5, size: 44, color: Colors.white),
                      ),
                    )
                        .animate()
                        .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut)
                        .then()
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenue !',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour suivre votre santé',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
                    const SizedBox(height: 40),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Iconsax.sms, color: AppColors.primary, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                            color: AppColors.textLight,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Mot de passe requis';
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                    const SizedBox(height: 12),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppColors.primary)),
                      ),
                    ).animate().fadeIn(delay: 550.ms),
                    const SizedBox(height: 24),

                    // Login button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        shadowColor: AppColors.primary.withAlpha(102),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15).scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 16),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas de compte ? ", style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: const Text(
                            'Inscrivez-vous',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
