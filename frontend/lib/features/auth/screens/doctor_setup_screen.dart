import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/data/providers/service_providers.dart';

// ── Doctor Green Theme ──────────────────────────────────────────────────
class _DC {
  static const Color primary      = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF388E3C);
  static const Color primaryDark  = Color(0xFF1B5E20);
  static const Color accent       = Color(0xFF00897B);
  static const Color bg           = Color(0xFFF1F8F1);
  static const Color surface      = Colors.white;
  static const Color textPrimary  = Color(0xFF1B2E1B);
  static const Color textSub      = Color(0xFF5A6A5A);
  static const Color error        = Color(0xFFD32F2F);
  static const Color success      = Color(0xFF2E7D32);
}

/// Doctor setup screen — called after signup+verify for role='D' users.
/// Collects: ville, address, experience, consultation_price, bio, speciality_id, user_id
/// POST /doctors/DoctorService/create_doctor/
class DoctorSetupScreen extends ConsumerStatefulWidget {
  final String email;
  final int userId;
  const DoctorSetupScreen({super.key, required this.email, required this.userId});

  @override
  ConsumerState<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends ConsumerState<DoctorSetupScreen>
    with TickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _expCtrl     = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _bioCtrl     = TextEditingController();
  final _specIdCtrl  = TextEditingController();
  final _userIdCtrl  = TextEditingController();

  String _ville    = 'TUNIS';
  bool _isLoading  = false;
  int _currentStep = 0;

  late final AnimationController _bgCtrl;
  late final AnimationController _pulseCtrl;

  static const _villeChoices = [
    'TUNIS','ARIANA','BEN_AROUS','MANOUBA','NABEUL','ZAGHOUAN',
    'BIZERTE','BEJA','JENDOUBA','KEF','SILIANA','SOUSSE',
    'MONASTIR','MAHDIA','SFAX','KAIROUAN','KASSERINE','SIDI_BOUZID',
    'GABES','MEDENINE','TATAOUINE','GAFSA','TOZEUR','KEBILI',
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _addressCtrl.dispose();
    _expCtrl.dispose();
    _priceCtrl.dispose();
    _bioCtrl.dispose();
    _specIdCtrl.dispose();
    _userIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final specialityId = int.tryParse(_specIdCtrl.text.trim());
    if (specialityId == null) {
      _snack('ID de spécialité invalide', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    int resolvedUserId = widget.userId;
    if (resolvedUserId == 0) {
      resolvedUserId = int.tryParse(_userIdCtrl.text.trim()) ?? 0;
    }
    if (resolvedUserId == 0) {
      _snack('ID utilisateur invalide. Contactez le support.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final payload = <String, dynamic>{
      'ville': _ville,
      'address': _addressCtrl.text.trim(),
      'experience': int.tryParse(_expCtrl.text.trim()) ?? 0,
      'user_id': resolvedUserId,
      'speciality_id': specialityId,
    };
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price != null) payload['consultation_price'] = price;
    final bio = _bioCtrl.text.trim();
    if (bio.isNotEmpty) payload['bio'] = bio;

    final result = await ref.read(doctorServiceProvider).createDoctor(payload);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _snack('Profil médecin créé ! Connectez-vous.', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.go('/login');
    } else {
      final msg = result['message'];
      String display;
      if (msg is Map) {
        display = msg.values
            .expand((v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
            .join('\n');
      } else {
        display = msg?.toString() ?? 'Erreur lors de la création du profil';
      }
      _snack(display, isError: true);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Iconsax.warning_2 : Iconsax.tick_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? _DC.error : _DC.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _next() {
    if (_currentStep < 2) setState(() => _currentStep++);
    else _submit();
  }

  void _back() {
    if (_currentStep > 0) setState(() => _currentStep--);
    else context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DC.bg,
      body: Stack(
        children: [
          _AnimatedBg(ctrl: _bgCtrl),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStepIndicator(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        key: ValueKey(_currentStep),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_DC.primaryDark, _DC.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _back,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 22),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Étape ${_currentStep + 1}/3',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + (_pulseCtrl.value * 0.04),
              child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(80), width: 2),
                ),
                child: const Icon(Iconsax.hospital, color: Colors.white, size: 34),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.7, 0.7)),
          const SizedBox(height: 12),
          const Text('Profil Médecin',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 4),
          Text(widget.email,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Infos Pro', 'Cabinet', 'Bio'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < _currentStep;
          final current = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: current ? 36 : 30, height: current ? 36 : 30,
                        decoration: BoxDecoration(
                          color: done || current ? _DC.primary : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done || current ? _DC.primary : _DC.textSub.withAlpha(80),
                            width: 2,
                          ),
                          boxShadow: current
                              ? [BoxShadow(color: _DC.primary.withAlpha(80), blurRadius: 10)]
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                    color: current ? Colors.white : _DC.textSub,
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: current ? _DC.primary : _DC.textSub,
                          fontWeight: current ? FontWeight.w700 : FontWeight.normal,
                        )),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: i < _currentStep
                              ? [_DC.primary, _DC.primaryLight]
                              : [Colors.grey.withAlpha(80), Colors.grey.withAlpha(40)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      default: return _buildStep2();
    }
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Iconsax.health, 'Informations professionnelles'),
        const SizedBox(height: 4),
        _sectionSubtitle('Renseignez votre spécialité et votre expérience.'),
        const SizedBox(height: 20),
        if (widget.userId == 0) ...[
          _infoBox(icon: Iconsax.warning_2, color: _DC.error,
            title: 'ID utilisateur requis',
            text: 'La session a expiré. Entrez l\'ID reçu lors de l\'inscription.'),
          const SizedBox(height: 12),
          _field(ctrl: _userIdCtrl, label: 'ID Utilisateur *', icon: Iconsax.user,
            type: TextInputType.number, hint: 'Ex: 5',
            validator: (v) {
              if (widget.userId != 0) return null;
              if (v == null || v.isEmpty) return 'Requis';
              if ((int.tryParse(v) ?? 0) <= 0) return 'ID invalide';
              return null;
            }),
          const SizedBox(height: 16),
        ],
        _infoBox(icon: Iconsax.info_circle, color: _DC.accent,
          title: 'ID Spécialité',
          text: 'Contactez l\'administrateur pour obtenir l\'ID de votre spécialité médicale.'),
        const SizedBox(height: 12),
        _field(ctrl: _specIdCtrl, label: 'ID Spécialité *', icon: Iconsax.health,
          type: TextInputType.number, hint: 'Ex: 1',
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            if (int.tryParse(v) == null) return 'Nombre entier requis';
            return null;
          }),
        const SizedBox(height: 16),
        _field(ctrl: _expCtrl, label: 'Années d\'expérience *', icon: Iconsax.award,
          type: TextInputType.number, hint: 'Ex: 10',
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            if (int.tryParse(v) == null) return 'Nombre entier requis';
            return null;
          }),
        const SizedBox(height: 16),
        _field(ctrl: _priceCtrl, label: 'Prix de consultation (TND)', icon: Iconsax.money,
          type: const TextInputType.numberWithOptions(decimal: true), hint: 'Ex: 60.00'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Iconsax.hospital, 'Cabinet médical'),
        const SizedBox(height: 4),
        _sectionSubtitle('Indiquez l\'emplacement de votre cabinet.'),
        const SizedBox(height: 20),
        _label('Ville'),
        const SizedBox(height: 6),
        Container(
          decoration: _boxDeco(),
          child: DropdownButtonFormField<String>(
            initialValue: _ville,
            decoration: const InputDecoration(
              prefixIcon: Icon(Iconsax.location, color: _DC.primary, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(color: _DC.textPrimary, fontSize: 15),
            items: _villeChoices
                .map((v) => DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' '))))
                .toList(),
            onChanged: (v) => setState(() => _ville = v ?? 'TUNIS'),
          ),
        ),
        const SizedBox(height: 16),
        _field(ctrl: _addressCtrl, label: 'Adresse du cabinet *', icon: Iconsax.location,
          hint: 'Ex: 12 Rue Habib Bourguiba, Tunis',
          validator: (v) => v == null || v.isEmpty ? 'Adresse requise' : null),
        const SizedBox(height: 20),
        // Preview card
        Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [_DC.primary.withAlpha(30), _DC.accent.withAlpha(20)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: _DC.primary.withAlpha(50)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.location, color: _DC.primary, size: 36),
                const SizedBox(height: 8),
                Text(_ville.replaceAll('_', ' '),
                  style: const TextStyle(color: _DC.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(_addressCtrl.text.isEmpty ? 'Adresse non saisie' : _addressCtrl.text,
                  style: const TextStyle(color: _DC.textSub, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Iconsax.edit_2, 'Présentation'),
        const SizedBox(height: 4),
        _sectionSubtitle('Décrivez votre parcours et vos spécialités (optionnel).'),
        const SizedBox(height: 20),
        // Preview doctor card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_DC.primaryDark, _DC.primaryLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _DC.primary.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.white.withAlpha(30), shape: BoxShape.circle),
                child: const Icon(Iconsax.user, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dr.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(widget.email.split('@').first.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Iconsax.location, color: Colors.white60, size: 12),
                      const SizedBox(width: 4),
                      Text(_ville.replaceAll('_', ' '),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${_expCtrl.text.isEmpty ? "?" : _expCtrl.text} ans',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const Text('expérience', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 24),
        _label('Bio (optionnel)'),
        const SizedBox(height: 6),
        Container(
          decoration: _boxDeco(),
          child: TextFormField(
            controller: _bioCtrl,
            maxLines: 6, maxLength: 500,
            style: const TextStyle(color: _DC.textPrimary, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Parlez de votre parcours, vos spécialités, votre approche médicale...',
              hintStyle: TextStyle(color: _DC.textSub.withAlpha(150), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: const TextStyle(color: _DC.textSub, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _tipCard(Iconsax.lamp_on, 'Conseil',
          'Une bonne bio rassure les patients et améliore votre visibilité sur la plateforme.'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: _DC.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
            child: Container(
              height: 52, width: 52,
              decoration: BoxDecoration(
                color: _DC.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _DC.primary.withAlpha(60)),
              ),
              child: const Icon(Iconsax.arrow_left, color: _DC.primary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _next,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_DC.primaryDark, _DC.primaryLight],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _DC.primary.withAlpha(100), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isLast ? 'Créer mon profil' : 'Suivant',
                              style: const TextStyle(color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                            const SizedBox(width: 8),
                            Icon(isLast ? Iconsax.tick_circle : Iconsax.arrow_right,
                              color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────
  Widget _sectionTitle(IconData icon, String text) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _DC.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _DC.primary, size: 20),
      ),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(color: _DC.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
    ],
  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);

  Widget _sectionSubtitle(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: const TextStyle(color: _DC.textSub, fontSize: 13)),
  ).animate().fadeIn(delay: 100.ms);

  Widget _label(String text) => Text(text,
    style: const TextStyle(color: _DC.textPrimary, fontSize: 13, fontWeight: FontWeight.w600));

  BoxDecoration _boxDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [BoxShadow(color: _DC.primary.withAlpha(18), blurRadius: 12, offset: const Offset(0, 4))],
    border: Border.all(color: _DC.primary.withAlpha(30)),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? type,
    String? hint,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      const SizedBox(height: 6),
      Container(
        decoration: _boxDeco(),
        child: TextFormField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: _DC.textPrimary, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _DC.textSub.withAlpha(150), fontSize: 13),
            prefixIcon: Icon(icon, color: _DC.primary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            errorStyle: const TextStyle(color: _DC.error, fontSize: 11),
          ),
        ),
      ),
    ],
  );

  Widget _infoBox({required IconData icon, required Color color, required String title, required String text}) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: _DC.textSub, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _tipCard(IconData icon, String title, String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_DC.accent.withAlpha(25), _DC.primary.withAlpha(15)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _DC.accent.withAlpha(60)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _DC.accent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: _DC.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(color: _DC.textSub, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
}

// ── Animated background ────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController ctrl;
  const _AnimatedBg({required this.ctrl});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ctrl,
    builder: (_, __) => CustomPaint(painter: _BgPainter(ctrl.value), size: Size.infinite),
  );
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF1F8F1));
    final offset = math.sin(t * math.pi) * 30;
    canvas.drawCircle(Offset(size.width * 0.85, -40 + offset), 140,
        Paint()..color = const Color(0xFF2E7D32).withAlpha(18));
    canvas.drawCircle(Offset(-40, size.height * 0.3 - offset * 0.5), 110,
        Paint()..color = const Color(0xFF00897B).withAlpha(15));
    canvas.drawCircle(Offset(size.width * 0.5, size.height + 20 - offset * 0.3), 160,
        Paint()..color = const Color(0xFF388E3C).withAlpha(12));
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}
