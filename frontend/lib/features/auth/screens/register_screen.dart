import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

/// Register screen — matches backend User model:
/// first_name, last_name, birth_date, email, phone, gender, role, password
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'F'; // Default female for pregnancy app
  String _role = 'P';   // Default patient
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  int _currentStep = 0;

  // ---------- password validation helpers ----------
  bool _hasMinLength(String v) => v.length >= 8;
  bool _hasUppercase(String v) => v.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase(String v) => v.contains(RegExp(r'[a-z]'));
  bool _hasDigit(String v) => v.contains(RegExp(r'[0-9]'));
  bool _hasSpecial(String v) => v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));

  int _strengthScore(String v) {
    int s = 0;
    if (_hasMinLength(v)) s++;
    if (_hasUppercase(v)) s++;
    if (_hasLowercase(v)) s++;
    if (_hasDigit(v)) s++;
    if (_hasSpecial(v)) s++;
    return s;
  }

  Color _strengthColor(int score) {
    if (score <= 1) return Colors.red;
    if (score == 2) return Colors.orange;
    if (score == 3) return Colors.amber;
    if (score == 4) return Colors.lightGreen;
    return Colors.green;
  }

  String _strengthLabel(int score) {
    if (score <= 1) return 'Très faible';
    if (score == 2) return 'Faible';
    if (score == 3) return 'Moyen';
    if (score == 4) return 'Fort';
    return 'Très fort';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (!_hasMinLength(v)) return 'Minimum 8 caractères';
    if (!_hasUppercase(v)) return 'Au moins une lettre majuscule (A–Z)';
    if (!_hasLowercase(v)) return 'Au moins une lettre minuscule (a–z)';
    if (!_hasDigit(v)) return 'Au moins un chiffre (0–9)';
    if (!_hasSpecial(v)) return 'Au moins un caractère spécial (!@#\$%…)';
    return null;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'birth_date': '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
      'gender': _gender,
      'role': _role,
    };

    final result = await ref.read(authProvider.notifier).signup(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      context.push('/verify', extra: _emailCtrl.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de l\'inscription'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Progress indicator
                _buildStepIndicator(),
                const SizedBox(height: 24),

                if (_currentStep == 0) ..._buildStep1(),
                if (_currentStep == 1) ..._buildStep2(),
                if (_currentStep == 2) ..._buildStep3(),

                const SizedBox(height: 24),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          child: const Text('Retour'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_currentStep == 0) {
                                  // Validate step 1: names + birth date
                                  if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Veuillez remplir prénom et nom'), backgroundColor: AppColors.error),
                                    );
                                    return;
                                  }
                                  if (_birthDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Veuillez sélectionner votre date de naissance'), backgroundColor: AppColors.error),
                                    );
                                    return;
                                  }
                                  setState(() => _currentStep++);
                                } else if (_currentStep == 1) {
                                  // Validate step 2: email + phone
                                  if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Email invalide'), backgroundColor: AppColors.error),
                                    );
                                    return;
                                  }
                                  final phone = _phoneCtrl.text.trim();
                                  final phoneRegex = RegExp(r'^\+?\d{8,15}$');
                                  if (phone.isEmpty || !phoneRegex.hasMatch(phone)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Numéro de téléphone invalide (ex: +21620123456 ou 20123456)'), backgroundColor: AppColors.error),
                                    );
                                    return;
                                  }
                                  setState(() => _currentStep++);
                                } else {
                                  _handleRegister();
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_currentStep < 2 ? 'Suivant' : 'S\'inscrire'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i <= _currentStep ? AppColors.primary : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildStep1() {
    return [
      Text('Informations personnelles', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextFormField(
        controller: _firstNameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Iconsax.user, color: AppColors.primary, size: 20)),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Prénom requis';
          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(v.trim())) return 'Lettres uniquement (sans espaces ni accents)';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _lastNameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Iconsax.user, color: AppColors.primary, size: 20)),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Nom requis';
          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(v.trim())) return 'Lettres uniquement (sans espaces ni accents)';
          return null;
        },
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _pickBirthDate,
        child: AbsorbPointer(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: _birthDate != null
                  ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                  : 'Date de naissance',
              prefixIcon: const Icon(Iconsax.calendar, color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildStep2() {
    return [
      Text('Contact & Rôle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Iconsax.sms, color: AppColors.primary, size: 20)),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email requis';
          if (!v.contains('@')) return 'Email invalide';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Iconsax.call, color: AppColors.primary, size: 20), hintText: '+216...'),
        validator: (v) => v == null || v.isEmpty ? 'Téléphone requis' : null,
      ),
      const SizedBox(height: 16),
      // Gender
      Text('Genre', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(
        children: [
          _buildChoiceChip('Femme', 'F', _gender, (v) => setState(() => _gender = v)),
          const SizedBox(width: 12),
          _buildChoiceChip('Homme', 'M', _gender, (v) => setState(() => _gender = v)),
        ],
      ),
      const SizedBox(height: 16),
      // Role
      Text('Vous êtes', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Row(
        children: [
          _buildChoiceChip('Patient(e)', 'P', _role, (v) => setState(() => _role = v)),
          const SizedBox(width: 12),
          _buildChoiceChip('Médecin', 'D', _role, (v) => setState(() => _role = v)),
        ],
      ),
    ];
  }

  List<Widget> _buildStep3() {
    return [
      Text('Mot de passe', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscure1,
        onChanged: (v) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscure1 ? Iconsax.eye_slash : Iconsax.eye, color: AppColors.textLight),
            onPressed: () => setState(() => _obscure1 = !_obscure1),
          ),
        ),
        validator: _validatePassword,
      ),
      if (_passwordCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final score = _strengthScore(_passwordCtrl.text);
          final color = _strengthColor(score);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i < score ? color : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 4),
              Text(_strengthLabel(score), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _PasswordRule('8 caractères minimum', _hasMinLength(_passwordCtrl.text)),
              _PasswordRule('Une majuscule (A–Z)', _hasUppercase(_passwordCtrl.text)),
              _PasswordRule('Une minuscule (a–z)', _hasLowercase(_passwordCtrl.text)),
              _PasswordRule('Un chiffre (0–9)', _hasDigit(_passwordCtrl.text)),
              _PasswordRule('Un caractère spécial (!@#\$%…)', _hasSpecial(_passwordCtrl.text)),
            ],
          );
        }),
      ],
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordCtrl,
        obscureText: _obscure2,
        decoration: InputDecoration(
          labelText: 'Confirmer le mot de passe',
          prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscure2 ? Iconsax.eye_slash : Iconsax.eye, color: AppColors.textLight),
            onPressed: () => setState(() => _obscure2 = !_obscure2),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Confirmation requise';
          if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
          return null;
        },
      ),
    ];
  }

  Widget _buildChoiceChip(String label, String value, String groupValue, ValueChanged<String> onSelected) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  final String label;
  final bool met;
  const _PasswordRule(this.label, this.met);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14, color: met ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: met ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }
}

