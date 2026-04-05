import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  int _step = 0; // 0 = email, 1 = code, 2 = new password
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final result = await ref.read(authServiceProvider).verifyResetEmail(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      setState(() => _step = 1);
    } else {
      _showError(result['message'] ?? 'Email introuvable');
    }
  }

  Future<void> _verifyResetCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final result = await ref.read(authServiceProvider).verifyResetCode(_emailCtrl.text.trim(), _codeCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      setState(() => _step = 2);
    } else {
      _showError(result['message'] ?? 'Code incorrect');
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordCtrl.text != _confirmCtrl.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }
    if (_newPasswordCtrl.text.length < 8) {
      _showError('Minimum 8 caractères');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref.read(authServiceProvider).forgetPassword(
      _emailCtrl.text.trim(),
      _newPasswordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe changé ! Connectez-vous.'), backgroundColor: AppColors.success),
      );
      context.go('/login');
    } else {
      _showError(result['message'] ?? 'Erreur');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                _step == 0 ? Icons.email_outlined : _step == 1 ? Icons.pin_outlined : Icons.lock_reset,
                size: 60,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              if (_step == 0) ...[
                Text('Entrez votre email', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Nous enverrons un code de vérification à votre email.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Envoyer le code'),
                ),
              ],

              if (_step == 1) ...[
                Text('Entrez le code', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Code envoyé à ${_emailCtrl.text}', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Code de vérification', prefixIcon: Icon(Icons.pin_outlined, color: AppColors.primary)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyResetCode,
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Vérifier'),
                ),
              ],

              if (_step == 2) ...[
                Text('Nouveau mot de passe', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer',
                    prefixIcon: Icon(Icons.lock_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Changer le mot de passe'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
