import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0; // 0 = send code, 1 = verify code, 2 = new password
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _email => ref.read(authProvider).email ?? '';

  Future<void> _sendResetCode() async {
    if (_email.isEmpty) {
      _showError('Email non trouvé');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref.read(authServiceProvider).verifyResetEmail(_email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 1);
      _showSuccess('Code envoyé à $_email');
    } else {
      _showError(result['message'] ?? 'Erreur');
    }
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().isEmpty) {
      _showError('Veuillez saisir le code');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref.read(authServiceProvider).verifyResetCode(_email, _codeCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 2);
    } else {
      _showError(result['message'] ?? 'Code incorrect');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text.length < 8) {
      _showError('Minimum 8 caractères');
      return;
    }
    if (_newPasswordCtrl.text != _confirmCtrl.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref.read(authServiceProvider).forgetPassword(_email, _newPasswordCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Mot de passe changé avec succès !'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } else {
      _showError(result['message'] ?? 'Erreur');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.arrow_left, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.warning.withAlpha(15), shape: BoxShape.circle),
                      child: const Icon(Iconsax.lock, color: AppColors.warning, size: 48),
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  const Center(child: Text('Sécurité du compte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),

                  // Step indicators
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) => Container(
                        width: _step == i ? 28 : 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _step >= i ? AppColors.warning : AppColors.textLight.withAlpha(50),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      )),
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 32),

                  if (_step == 0) _buildStep0(),
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info.withAlpha(30)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.info_circle, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Un code de vérification sera envoyé à\n$_email',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Iconsax.sms, color: Colors.white), SizedBox(width: 8), Text('Envoyer le code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
                  ),
          ),
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Code de vérification', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Saisissez le code reçu',
            prefixIcon: const Icon(Iconsax.lock, color: AppColors.warning, size: 20),
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Vérifier le code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nouveau mot de passe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPasswordCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            hintText: 'Minimum 8 caractères',
            prefixIcon: const Icon(Iconsax.lock, color: AppColors.warning, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Iconsax.eye_slash : Iconsax.eye, color: AppColors.textLight),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
        const SizedBox(height: 16),
        const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'Retapez le mot de passe',
            prefixIcon: const Icon(Iconsax.lock, color: AppColors.warning, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Iconsax.eye_slash : Iconsax.eye, color: AppColors.textLight),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Iconsax.tick_circle, color: Colors.white), SizedBox(width: 8), Text('Changer le mot de passe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
                  ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }
}
