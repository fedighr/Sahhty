import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/widgets/wave_clipper.dart';
import 'package:sahhty/core/widgets/animated_week_counter.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _latestData;
  Map<String, dynamic>? _pregnancyData;
  Map<String, dynamic>? _riskData;
  int? _weekFromBackend;
  bool _loading = true;
  String? _error;

  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authProvider);
    final patientIdStr = auth.patientId;
    if (patientIdStr == null || patientIdStr.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'ID patient non trouvé';
      });
      return;
    }
    final patientId = int.tryParse(patientIdStr);
    if (patientId == null) {
      setState(() {
        _loading = false;
        _error = 'ID patient invalide';
      });
      return;
    }

    try {
      final results = await Future.wait([
        ref.read(measurementServiceProvider).getLatestMeasurements(patientId),
        ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId),
        ref.read(measurementServiceProvider).getRiskAssessment(patientId),
      ]);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (results[0]['success'] == true) _latestData = results[0];
        if (results[1]['success'] == true) {
          _pregnancyData = results[1]['pregnancy'];
          _weekFromBackend = results[1]['week'] as int?;
        }
        if (results[2]['success'] == true) _riskData = results[2]['risk_assessment'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  int get _pregnancyWeeks {
    if (_weekFromBackend != null) return _weekFromBackend!;
    if (_pregnancyData == null || _pregnancyData!['start_date'] == null) return 0;
    final start = DateTime.tryParse(_pregnancyData!['start_date'].toString());
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays ~/ 7;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: Stack(
        children: [
          // Beautiful image background with soft overlay
          const AnimatedBackground(showImage: true, imageOpacity: 0.10),
          // Light floating particles
          const FloatingParticles(particleCount: 22, maxOpacity: 0.25),
          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: _loading
                  ? _buildShimmerLoading()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopHeader(auth),
                          if (_error != null) ...[
                            _buildErrorBanner(),
                          ] else ...[
                            if (_pregnancyData != null) _buildPregnancyBanner(),
                            if (_riskData != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildRiskCard(),
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                            const SizedBox(height: 20),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildMeasurementsSection(),
                            const SizedBox(height: 16),
                            _buildMotivationalCard(),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MOTIVATIONAL CARD ───────────────────────────────────────────────
  Widget _buildMotivationalCard() {
    final messages = [
      'Vous êtes incroyable 💕 Chaque jour compte !',
      'Prenez soin de vous et de votre bébé 🌸',
      'Vous faites un travail extraordinaire 🦋',
      'Votre santé est notre priorité 💖',
    ];
    final msg = messages[DateTime.now().day % messages.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withAlpha(80),
              AppColors.primaryLight.withAlpha(60),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withAlpha(30)),
        ),
        child: Row(
          children: [
            const Text('🌷', style: TextStyle(fontSize: 36))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -0.03, end: 0.03, duration: 2000.ms, curve: Curves.easeInOut),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15);
  }

  // ── SHIMMER LOADING ───────────────────────────────────────────────
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 14, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(width: 150, height: 18, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ],
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
          const SizedBox(height: 24),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(24),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
          const SizedBox(height: 20),
          Row(
            children: List.generate(3, (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
          const SizedBox(height: 24),
          ...List.generate(3, (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
          )).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
        ],
      ),
    );
  }

  // ── TOP HEADER ────────────────────────────────────────────────────
  Widget _buildTopHeader(AuthState auth) {
    final name = auth.name ?? 'Utilisateur';
    final hour = DateTime.now().hour;
    String greeting;
    String greetEmoji;
    if (hour < 12) {
      greeting = 'Bonjour';
      greetEmoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
      greetEmoji = '🌤️';
    } else {
      greeting = 'Bonsoir';
      greetEmoji = '🌙';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withAlpha(30),
                AppColors.primaryLight.withAlpha(15),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Avatar with breathing animation
              AnimatedBuilder(
                animation: _breatheController,
                builder: (context, _) {
                  final scale = 1.0 + _breatheController.value * 0.04;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(77),
                            blurRadius: 12 + _breatheController.value * 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              )
                  .animate()
                  .scale(delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 2000.ms, delay: 500.ms, color: Colors.white24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(greetEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(greeting, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              ),
              _HeaderButton(icon: Icons.search_outlined, onTap: () => context.push('/medications'), tooltip: 'Rechercher')
                  .animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(width: 8),
              _HeaderButton(icon: Icons.local_hospital_outlined, onTap: () => context.push('/doctors'), tooltip: 'Médecins')
                  .animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
            ],
          ),
        ),
        AnimatedWave(height: 30, color: AppColors.primary.withAlpha(15)),
      ],
    );
  }

  // ── PREGNANCY BANNER ──────────────────────────────────────────────
  Widget _buildPregnancyBanner() {
    final dueDate = _pregnancyData!['due_date'];
    int? daysLeft;
    if (dueDate != null) {
      final due = DateTime.tryParse(dueDate.toString());
      if (due != null) daysLeft = due.difference(DateTime.now()).inDays;
    }
    final progress = (_pregnancyWeeks / 40).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => context.go('/pregnancy'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8878F), Color(0xFFD4646E), Color(0xFFC75B6A)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withAlpha(89), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedWeekCounter(weeks: _pregnancyWeeks, size: 80),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🤰', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          const Text('Ma grossesse', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Semaine $_pregnancyWeeks', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.1)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(38), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: 3, duration: 1500.ms, curve: Curves.easeInOut),
              ],
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: Colors.white.withAlpha(51),
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toInt()}% complété', style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12, fontWeight: FontWeight.w500)),
                if (daysLeft != null && daysLeft > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⏳', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text('$daysLeft jours restants', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 3000.ms, curve: Curves.easeInOut);
  }

  // ── RISK CARD ─────────────────────────────────────────────────────
  Widget _buildRiskCard() {
    final level = _riskData!['global_risk_level'] ?? 'LOW';
    final note = _riskData!['personal_risk_note'] ?? '';
    Color riskColor;
    IconData riskIcon;
    String riskLabel;
    String riskEmoji;
    switch (level) {
      case 'HIGH':
        riskColor = AppColors.riskHigh; riskIcon = Icons.dangerous_outlined; riskLabel = 'Risque élevé'; riskEmoji = '🚨'; break;
      case 'MEDIUM':
        riskColor = AppColors.riskMedium; riskIcon = Icons.warning_amber_rounded; riskLabel = 'Risque modéré'; riskEmoji = '⚠️'; break;
      default:
        riskColor = AppColors.riskLow; riskIcon = Icons.check_circle_outline; riskLabel = 'Risque faible'; riskEmoji = '✅';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withAlpha(15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: riskColor.withAlpha(64)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: riskColor.withAlpha(30), borderRadius: BorderRadius.circular(12)),
            child: Text(riskEmoji, style: const TextStyle(fontSize: 24)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1500.ms),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(riskLabel, style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 15)),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(note, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ).animate().fadeIn(delay: 50.ms),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _QuickActionCard(emoji: '📏', label: 'Nouvelle\nmesure', color: AppColors.primary, onTap: () => context.push('/add-measurement')).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(emoji: '💊', label: 'Mes\nmédicaments', color: AppColors.accent, onTap: () => context.push('/medications')).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(emoji: '🔔', label: 'Mes\nalertes', color: AppColors.warning, onTap: () => context.go('/alerts')).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)),
            ],
          ),
        ],
      ),
    );
  }

  // ── MEASUREMENTS SECTION ──────────────────────────────────────────
  Widget _buildMeasurementsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  const Text('Dernières mesures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/measurements'),
                icon: const Text('Voir tout', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                label: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
              ),
            ],
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 8),
          if (_latestData != null) _buildMeasurementsGrid() else _buildEmptyMeasurements(),
        ],
      ),
    );
  }

  Widget _buildMeasurementsGrid() {
    final data = _latestData!;
    final items = <_MeasureData>[
      _MeasureData(emoji: '⚖️', label: 'Poids', value: '${data['weight'] ?? '--'}', unit: 'kg', color: AppColors.primary),
      _MeasureData(emoji: '📊', label: 'IMC', value: '${data['bmi'] ?? '--'}', unit: '', color: AppColors.accent),
      _MeasureData(emoji: '🩸', label: 'Glycémie',
        value: data['glycemia_informations'] != null ? '${data['glycemia_informations']['value1']}' : '--',
        unit: data['glycemia_informations'] != null ? '${data['glycemia_informations']['unit'] ?? ''}' : '', color: AppColors.info),
      _MeasureData(emoji: '❤️', label: 'Tension',
        value: data['blood_pressure'] != null ? '${data['blood_pressure']['value1']}/${data['blood_pressure']['value2']}' : '--',
        unit: 'mmHg', color: AppColors.error),
      _MeasureData(emoji: '💓', label: 'Rythme', value: data['heart_rate'] != null ? '${data['heart_rate']['value1']}' : '--', unit: 'bpm', color: AppColors.primaryDark),
      _MeasureData(emoji: '🌡️', label: 'Temp.', value: data['body_temp'] != null ? '${data['body_temp']['value1']}' : '--', unit: '°C', color: AppColors.warning),
    ];
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: _MeasureCard(data: items[i]).animate().fadeIn(delay: (100 * (i ~/ 2 + 1) + 400).ms).slideY(begin: 0.15).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms)),
                const SizedBox(width: 12),
                Expanded(child: i + 1 < items.length
                    ? _MeasureCard(data: items[i + 1]).animate().fadeIn(delay: (100 * (i ~/ 2 + 1) + 450).ms).slideY(begin: 0.15).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms)
                    : const SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyMeasurements() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(77),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(25)),
      ),
      child: Column(
        children: [
          const Text('📏', style: TextStyle(fontSize: 48))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.05, end: 0.05, duration: 2000.ms),
          const SizedBox(height: 12),
          const Text('Aucune mesure enregistrée', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Ajoutez vos premières mesures pour\nsuivre votre santé', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-measurement'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter une mesure'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withAlpha(51)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? 'Erreur', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(160, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().shake(delay: 300.ms, hz: 2, offset: const Offset(4, 0));
  }
}

// ═══════════════════════════════════════════════════════════════════════
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _HeaderButton({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.emoji, required this.label, required this.color, required this.onTap});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withAlpha(38)),
            boxShadow: _pressed
                ? []
                : [BoxShadow(color: widget.color.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(widget.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.color, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasureData {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MeasureData({required this.emoji, required this.label, required this.value, required this.unit, required this.color});
}

class _MeasureCard extends StatelessWidget {
  final _MeasureData data;
  const _MeasureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
        border: Border(
          left: BorderSide(color: data.color.withAlpha(102), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [data.color.withAlpha(38), data.color.withAlpha(13)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(height: 12),
          Text(data.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: Text(data.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              if (data.unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(data.unit, style: TextStyle(fontSize: 11, color: data.color, fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Needed to use AnimatedBuilder from wave_clipper without conflict
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  const AnimatedBuilder({super.key, required Animation<double> animation, required this.builder})
      : super(listenable: animation);
  @override
  Widget build(BuildContext context) => builder(context, null);
}
