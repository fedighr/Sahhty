import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() { _loading = true; _error = null; });
    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(patientServiceProvider).getPatientById(patientId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final p = result['patient'];
        _firstNameCtrl.text = p['first_name'] ?? '';
        _lastNameCtrl.text = p['last_name'] ?? '';
        _phoneCtrl.text = p['phone'] ?? '';
        if (p['birth_date'] != null) {
          _selectedBirthDate = DateTime.tryParse(p['birth_date'].toString());
          _birthDateCtrl.text = p['birth_date'].toString();
        }
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    };
    if (_selectedBirthDate != null) {
      data['birth_date'] = _birthDateCtrl.text;
    }

    final result = await ref.read(patientServiceProvider).updatePatient(patientId, data);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Iconsax.tick_circle, color: Colors.white, size: 20), SizedBox(width: 8), Text('Profil mis à jour !')]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Modifier le profil', style: TextStyle(fontWeight: FontWeight.bold)),
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
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Iconsax.close_circle, size: 48, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _loadPatientData, child: const Text('Réessayer')),
                    ]))
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header icon
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Iconsax.user, color: AppColors.primary, size: 48),
                                ),
                              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 24),
                              Center(
                                child: Text('Informations personnelles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 8),
                              Center(
                                child: Text('Modifiez vos informations de profil', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              ).animate().fadeIn(delay: 150.ms),
                              const SizedBox(height: 32),

                              _buildLabel('Prénom'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _firstNameCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Votre prénom',
                                  prefixIcon: const Icon(Iconsax.user, color: AppColors.primary, size: 20),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Nom'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _lastNameCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Votre nom',
                                  prefixIcon: Icon(Iconsax.user, color: AppColors.primary, size: 20),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Téléphone'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: '+213 XX XXX XXXX',
                                  prefixIcon: const Icon(Iconsax.call, color: AppColors.primary, size: 20),
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Date de naissance'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _birthDateCtrl,
                                readOnly: true,
                                onTap: _pickBirthDate,
                                decoration: const InputDecoration(
                                  hintText: 'Sélectionner une date',
                                  prefixIcon: const Icon(Iconsax.calendar, color: AppColors.primary, size: 20),
                                  suffixIcon: const Icon(Iconsax.calendar, color: AppColors.textLight, size: 20),
                                ),
                              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                              const SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _saving
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Iconsax.tick_circle),
                                            SizedBox(width: 8),
                                            Text('Enregistrer'),
                                          ],
                                        ),
                                ),
                              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary));
  }
}
