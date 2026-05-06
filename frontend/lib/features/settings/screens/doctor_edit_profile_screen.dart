import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

class DoctorEditProfileScreen extends ConsumerStatefulWidget {
  const DoctorEditProfileScreen({super.key});

  @override
  ConsumerState<DoctorEditProfileScreen> createState() => _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends ConsumerState<DoctorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _villeCtrl.dispose();
    _addressCtrl.dispose();
    _experienceCtrl.dispose();
    _priceCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorData() async {
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authProvider);
    final doctorId = int.tryParse(auth.doctorId ?? '');
    if (doctorId == null) {
      final nameParts = (auth.name ?? '').split(' ');
      _firstNameCtrl.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameCtrl.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      setState(() { _loading = false; });
      return;
    }
    final result = await ref.read(doctorServiceProvider).getDoctorById(doctorId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final d = result['doctor'];
        _firstNameCtrl.text = d['first_name'] ?? '';
        _lastNameCtrl.text = d['last_name'] ?? '';
        _phoneCtrl.text = d['phone'] ?? '';
        _villeCtrl.text = d['ville'] ?? '';
        _addressCtrl.text = d['address'] ?? '';
        _experienceCtrl.text = d['experience']?.toString() ?? '';
        _priceCtrl.text = d['consultation_price']?.toString() ?? '';
        _bioCtrl.text = d['bio'] ?? '';
      } else {
        // Doctor not yet verified — pre-fill basic info from auth state
        final nameParts = (auth.name ?? '').split(' ');
        _firstNameCtrl.text = nameParts.isNotEmpty ? nameParts.first : '';
        _lastNameCtrl.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final doctorId = int.tryParse(ref.read(authProvider).doctorId ?? '');
    if (doctorId == null) return;

    setState(() => _saving = true);
    final payload = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'ville': _villeCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      if (_experienceCtrl.text.isNotEmpty) 'experience': int.tryParse(_experienceCtrl.text.trim()) ?? 0,
      if (_priceCtrl.text.isNotEmpty) 'consultation_price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      'bio': _bioCtrl.text.trim(),
    };

    final result = await ref.read(doctorServiceProvider).updateDoctor(doctorId, payload);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Profil mis à jour avec succès'),
        ]),
        backgroundColor: DoctorColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      context.pop();
    } else {
      final msg = result['message'];
      final errMsg = msg is Map ? msg.values.first.toString() : msg?.toString() ?? 'Erreur';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Iconsax.close_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(errMsg)),
        ]),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: DoctorColors.primary,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DoctorColors.primaryDark, DoctorColors.primary, Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Iconsax.user_edit, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modifier le profil',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Informations du médecin',
                                style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _loading
                ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: DoctorColors.primary)))
                : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.red.withAlpha(20), shape: BoxShape.circle),
            child: const Icon(Iconsax.close_circle, size: 40, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadDoctorData,
            icon: const Icon(Iconsax.refresh_2),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: DoctorColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(Iconsax.user, 'Informations personnelles'),
            const SizedBox(height: 12),
            _field(_firstNameCtrl, 'Prénom', Iconsax.user, required: true),
            const SizedBox(height: 12),
            _field(_lastNameCtrl, 'Nom', Iconsax.user, required: true),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'Téléphone', Iconsax.call, keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            _sectionLabel(Iconsax.hospital, 'Informations professionnelles'),
            const SizedBox(height: 12),
            _field(_villeCtrl, 'Ville', Iconsax.location),
            const SizedBox(height: 12),
            _field(_addressCtrl, 'Adresse du cabinet', Iconsax.location),
            const SizedBox(height: 12),
            _field(_experienceCtrl, 'Années d\'expérience', Iconsax.clock, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field(_priceCtrl, 'Prix de consultation (TND)', Iconsax.money_2, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            _field(_bioCtrl, 'Biographie', Iconsax.edit_2, maxLines: 4),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DoctorColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 18, color: DoctorColors.primary),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DoctorColors.textPrimary)),
    ]).animate().fadeIn();
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: DoctorColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: DoctorColors.textSecondary),
        prefixIcon: Icon(icon, color: DoctorColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DoctorColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 14),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label est requis' : null : null,
    ).animate().fadeIn();
  }
}
