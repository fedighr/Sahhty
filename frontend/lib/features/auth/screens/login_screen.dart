import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/core/providers/websocket_provider.dart';

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
      _registerFcmDevice();
      ref.read(webSocketServiceProvider).connect();
      context.go(auth.role == 'D' ? '/doctor-home' : '/home');
    } else if (auth.status == AuthStatus.needs2FA) {
      context.push('/verify-2fa', extra: _emailController.text.trim());
    } else if (auth.status == AuthStatus.needsVerification) {
      context.push('/verify', extra: _emailController.text.trim());
    } else if (auth.status == AuthStatus.needsProfileSetup) {
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
    const blueAccent = Color(0xFF2196F3);
    const blueDark = Color(0xFF1565C0);
    const blueMid = Color(0xFF1976D2);

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE8F4FD),
              Color(0xFFD0E8F8),
              Color(0xFFBBDAF3),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative top circle
            Positioned(
              top: -100,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueAccent.withAlpha(18),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueDark.withAlpha(12),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 50),
                      // Logo
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: blueAccent.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo2.png',
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              errorBuilder: (ctx, err, st) => const Icon(
                                Iconsax.heart5,
                                color: blueAccent,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut)
                          .then()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 2200.ms, curve: Curves.easeInOut),
                      const SizedBox(height: 24),
                      const Text(
                        'Bienvenue !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: blueDark,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 8),
                      const Text(
                        'Connectez-vous pour suivre votre santé',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: blueMid,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
                      const SizedBox(height: 36),

                      // White card for form
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: blueAccent.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(color: blueMid),
                                prefixIcon: const Icon(Iconsax.sms, color: blueAccent, size: 20),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: blueAccent, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: blueAccent.withAlpha(60)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF0F7FF),
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
                                labelStyle: const TextStyle(color: blueMid),
                                prefixIcon: const Icon(Iconsax.lock, color: blueAccent, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                                    color: blueMid,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: blueAccent, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: blueAccent.withAlpha(60)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF0F7FF),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Mot de passe requis';
                                return null;
                              },
                            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                          ],
                        ),
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(color: blueMid),
                          ),
                        ),
                      ).animate().fadeIn(delay: 550.ms),
                      const SizedBox(height: 8),

                      // Login button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [blueAccent, blueDark],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: blueAccent.withAlpha(80),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15).scale(begin: const Offset(0.95, 0.95)),
                      const SizedBox(height: 20),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Pas de compte ? ", style: TextStyle(color: Color(0xFF546E7A))),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text(
                              'Inscrivez-vous',
                              style: TextStyle(
                                color: blueAccent,
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
      ),
    );
  }
}
