import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/widgets/animated_week_counter.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _pregnancyData;
  bool _loading = true;
  String? _error;
  late AnimationController _glowController;
  final Map<String, bool> _sectionExpanded = {
    'personal': false,
    'medical': false,
    'menstrual': false,
  };

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadProfile();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    final patientId = _getPatientId();
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final futures = await Future.wait([
      ref.read(patientServiceProvider).getPatientById(patientId),
      ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId),
    ]);

    if (!mounted) return;
    final patientResult = futures[0];
    final pregnancyResult = futures[1];

    setState(() {
      _loading = false;
      if (patientResult['success'] == true) {
        _patientData = patientResult['patient'];
      } else {
        _error = patientResult['message'] ?? 'Erreur';
      }
      if (pregnancyResult['success'] == true) {
        _pregnancyData = pregnancyResult['pregnancy'];
      }
    });
  }

  int? _getPatientId() => int.tryParse(ref.read(authProvider).patientId ?? '');

  String _menstrualStatusLabel(String? status) {
    switch (status) {
      case 'ACTIVE': return 'Actif';
      case 'MENOPAUSE': return 'Ménopause';
      case 'PREPUBESCENT': return 'Prépubère';
      default: return status ?? '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mon profil', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.setting_2, color: Colors.grey, size: 22),
            ),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Beautiful image background with stronger opacity for profile
          const AnimatedBackground(showImage: true, imageOpacity: 0.22),
          // Floating hearts in background
          const FloatingParticles(particleCount: 24, maxOpacity: 0.3),
          // Content
          _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      const Text('Chargement du profil...', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ).animate().fadeIn(),
                )
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Iconsax.close_circle, size: 64, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(Iconsax.refresh_2, size: 20),
                        label: const Text('Réessayer'),
                      ),
                    ]).animate().fadeIn().shake(hz: 1, offset: const Offset(4, 0)))
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                        child: Column(
                          children: [
                            _buildHeader().animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                            const SizedBox(height: 24),

                            if (_patientData != null) ...[
                              if (_pregnancyData != null) ...[
                                _buildPregnancyCard().animate().fadeIn(delay: 150.ms).slideX(begin: 0.1)
                                    .then()
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .moveY(begin: 0, end: -3, duration: 3000.ms, curve: Curves.easeInOut),
                                const SizedBox(height: 16),
                              ],

                              _buildCollapsibleSection('personal', Iconsax.user, 'Informations personnelles', [
                                _infoRow(Iconsax.sms, 'Email', _patientData!['email'] ?? '--'),
                                _infoRow(Iconsax.call, 'Téléphone', _patientData!['phone'] ?? '--'),
                                _infoRow(Iconsax.calendar, 'Date de naissance', '${_patientData!['birth_date'] ?? '--'}'),
                                _infoRow(Iconsax.clock, 'Âge', '${_patientData!['age'] ?? '--'} ans'),
                              ]).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),
                              const SizedBox(height: 16),

                              _buildCollapsibleSection('medical', Iconsax.hospital, 'Informations médicales', [
                                _infoRow(Iconsax.ruler, 'Taille', '${_patientData!['height'] ?? '--'} cm'),
                                _infoRow(Iconsax.weight, 'Poids', '${_patientData!['weight'] ?? '--'} kg'),
                                _infoRow(Iconsax.health, 'Groupe sanguin', _patientData!['blood_type'] ?? 'Non renseigné'),
                                if (_patientData!['chronic_diseases'] != null && _patientData!['chronic_diseases'].toString().isNotEmpty)
                                  _infoRow(Iconsax.health, 'Maladies chroniques', _patientData!['chronic_diseases']),
                                if (_patientData!['allergies'] != null && _patientData!['allergies'].toString().isNotEmpty)
                                  _infoRow(Iconsax.warning_2, 'Allergies', _patientData!['allergies']),
                                if (_patientData!['current_medications'] != null && _patientData!['current_medications'].toString().isNotEmpty)
                                  _infoRow(Iconsax.health, 'Médicaments actuels', _patientData!['current_medications']),
                                if (_patientData!['family_doctor_name'] != null && _patientData!['family_doctor_name'].toString().isNotEmpty)
                                  _infoRow(Iconsax.user, 'Médecin traitant', _patientData!['family_doctor_name']),
                              ]).animate().fadeIn(delay: 350.ms).slideY(begin: 0.08),

                              if (_patientData!['menstrual_cycle'] != null) ...[
                                const SizedBox(height: 16),
                                _buildCollapsibleSection('menstrual', Iconsax.calendar, 'Cycle menstruel', [
                                  _infoRow(Iconsax.chart_2, 'Statut', _menstrualStatusLabel(_patientData!['menstrual_cycle']['menstrual_status'])),
                                  if (_patientData!['menstrual_cycle']['start_date'] != null)
                                    _infoRow(Iconsax.calendar, 'Dernier début de cycle', '${_patientData!['menstrual_cycle']['start_date']}'),
                                  if (_patientData!['menstrual_cycle']['end_date'] != null)
                                    _infoRow(Iconsax.calendar, 'Dernière fin de cycle', '${_patientData!['menstrual_cycle']['end_date']}'),
                                  if (_patientData!['menstrual_cycle']['cycle_length'] != null)
                                    _infoRow(Iconsax.clock, 'Durée du cycle', '${_patientData!['menstrual_cycle']['cycle_length']} jours'),
                                ]).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08),
                              ],
                            ],

                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(child: _ShortcutButton(icon: Iconsax.health, label: 'Médicaments', color: AppColors.accent, onTap: () => context.push('/medications'))),
                                const SizedBox(width: 12),
                                Expanded(child: _ShortcutButton(icon: Iconsax.hospital, label: 'Médecins', color: AppColors.info, onTap: () => context.push('/doctors'))),
                              ],
                            ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),
                            const SizedBox(height: 32),

                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(authProvider.notifier).logout();
                                if (!context.mounted) return;
                                context.go('/login');
                              },
                              icon: const Icon(Iconsax.logout, color: AppColors.error, size: 24),
                              label: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: Colors.white.withAlpha(230),
                              ),
                            ).animate().fadeIn(delay: 650.ms),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildPregnancyCard() {
    final startDate = _pregnancyData!['start_date'];
    final dueDate = _pregnancyData!['due_date'];
    int? weeks;
    int? daysLeft;
    if (startDate != null) {
      final start = DateTime.tryParse(startDate.toString());
      if (start != null) weeks = DateTime.now().difference(start).inDays ~/ 7;
    }
    if (dueDate != null) {
      final due = DateTime.tryParse(dueDate.toString());
      if (due != null) daysLeft = due.difference(DateTime.now()).inDays;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(89), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          if (weeks != null)
            AnimatedWeekCounter(weeks: weeks, size: 90),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Iconsax.heart5, size: 20, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Grossesse en cours', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (daysLeft != null && daysLeft > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.clock, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('$daysLeft jours restants', style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                if (dueDate != null) ...[
                  const SizedBox(height: 6),
                  Text('Date prévue : $dueDate', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final firstName = _patientData?['first_name'];
    final lastName = _patientData?['last_name'];
    final name = (firstName != null && lastName != null)
        ? '$firstName $lastName'
        : (ref.read(authProvider).name ?? 'Utilisateur');
    final gender = _patientData?['gender'];

    return Column(
      children: [
        // Pulsing glow behind avatar
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring with animation
            GlowAnimatedBuilder(
              listenable: _glowController,
              builder: (context, _) {
                return Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withAlpha((51 + _glowController.value * 30).toInt()),
                        AppColors.primary.withAlpha((13 + _glowController.value * 15).toInt()),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(102), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ),
            )
                .animate()
                .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 2000.ms, color: Colors.white24),
          ],
        ),
        const SizedBox(height: 14),
        Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withAlpha(51)),
          ),
            child: Text(
              gender == 'F' ? 'Patiente' : 'Patient',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
      ],
    );
  }

  Widget _buildCollapsibleSection(String key, IconData icon, String title, List<Widget> children) {
    final expanded = _sectionExpanded[key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _sectionExpanded[key] = !expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 14, offset: const Offset(0, 4))],
          border: Border.all(color: expanded ? AppColors.primary.withAlpha(80) : Colors.white.withAlpha(153)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Iconsax.arrow_down, size: 20, color: AppColors.primary),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 14),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight.withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Icon(icon, size: 18, color: AppColors.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShortcutButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  State<_ShortcutButton> createState() => _ShortcutButtonState();
}

class _ShortcutButtonState extends State<_ShortcutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withAlpha(38)),
            boxShadow: _pressed ? [] : [BoxShadow(color: widget.color.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(widget.icon, size: 28, color: widget.color),
              const SizedBox(height: 6),
              Text(widget.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.color)),
            ],
          ),
        ),
      ),
    );
  }
}

class GlowAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  const GlowAnimatedBuilder({super.key, required super.listenable, required this.builder});
  @override
  Widget build(BuildContext context) => builder(context, null);
}
