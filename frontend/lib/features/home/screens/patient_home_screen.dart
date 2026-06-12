import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/widgets/wave_clipper.dart';
import 'package:sahhty/core/widgets/animated_week_counter.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/data/services/wearable_service.dart';
import 'package:sahhty/core/services/smartwatch_risk_service.dart';

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
  List<dynamic> _todayAppointments = [];
  int? _weekFromBackend;
  bool _loading = true;
  String? _error;

  // ── Male blue theme palette ──────────────────────────────────────
  static const Color _maleBlue      = Color(0xFF1565C0);
  static const Color _maleBlueDark  = Color(0xFF0D47A1);
  static const Color _maleBlueLight = Color(0xFF42A5F5);
  static const Color _maleBluePale  = Color(0xFFE3F2FD);
  static const Color _maleTeal      = Color(0xFF00ACC1);

  late AnimationController _breatheController;

  @override
  void initState() {
      super.initState();
      _breatheController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      )..repeat(reverse: true);
      _loadData();
      _checkWearableApp();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(smartWatchRiskServiceProvider).riskEvents.listen((event) {
          if (mounted) _showWatchRiskAlert(event.riskLevel);
        });
      });
    }

  Future<void> _checkWearableApp() async {
    final result = await WearableService.checkWatchApp();
    if (!mounted) return;
    switch (result.status) {
      case WatchAppStatus.installed:
        debugPrint('[Wearable] Watch app installed.');
        break;
      case WatchAppStatus.notInstalled:
        _showWatchInstallDialog();
        break;
      case WatchAppStatus.noWatch:
        _showNoWatchDialog(result.message);
        break;
      case WatchAppStatus.error:
        debugPrint('[Wearable] Check error: ${result.message}');
        break;
    }
  }

  void _showWatchInstallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.watch, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Application Montre'),
          ],
        ),
        content: const Text(
          'Votre montre est connectée mais l\'application Sahhty n\'est pas encore installée. '
              'Voulez-vous l\'installer maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final sent = await WearableService.triggerWatchAppInstall();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(sent
                      ? 'Demande d\'installation envoyée à la montre ✓'
                      : 'Impossible d\'envoyer la demande. Réessayez.'),
                ));
              }
            },
            child: const Text('Installer'),
          ),
        ],
      ),
    );
  }
  void _showNoWatchDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.watch, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Aucune montre'),
          ],
        ),
        content: Text(
          '$message\n\nPour utiliser les fonctionnalités de suivi automatique, '
              'connectez une montre Wear OS compatible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWatchRiskAlert(String riskLevel) {
      final isHigh = riskLevel == 'HIGH';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Iconsax.warning_2,
                  color: isHigh ? AppColors.riskHigh : AppColors.riskMedium, size: 28),
              const SizedBox(width: 8),
              Text(
                isHigh ? 'Risque élevé !' : 'Attention',
                style: TextStyle(
                    color: isHigh ? AppColors.riskHigh : AppColors.riskMedium,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isHigh ? AppColors.riskHigh : AppColors.riskMedium).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isHigh
                  ? 'Un risque élevé a été détecté par votre montre. Veuillez consulter votre médecin immédiatement.'
                  : 'Un risque modéré a été détecté par votre montre. Surveillez vos mesures de près.',
              style: TextStyle(color: isHigh ? AppColors.riskHigh : AppColors.riskMedium),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isHigh ? AppColors.riskHigh : AppColors.riskMedium,
              ),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
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

    // Doctors don't have a patientId — show doctor home
    if (auth.role == 'D') {
      setState(() => _loading = false);
      return;
    }

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

    final isMale = auth.gender == 'M';
    try {
      if (isMale) {
        final results = await Future.wait([
          ref.read(measurementServiceProvider).getLatestMeasurements(patientId),
          ref.read(appointmentServiceProvider).getPatientTodayAppointments(patientId),
        ]);
        if (!mounted) return;
        setState(() {
          _loading = false;
          if (results[0]['success'] == true) _latestData = results[0];
          if (results[1]['success'] == true) {
            final appts = results[1]['appointments'];
            _todayAppointments = appts is List ? appts : [];
          }
        });
      } else {
      final results = await Future.wait([
        ref.read(measurementServiceProvider).getLatestMeasurements(patientId),
        ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId),
        ref.read(measurementServiceProvider).getRiskAssessment(patientId),
        ref.read(appointmentServiceProvider).getPatientTodayAppointments(patientId),
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
        if (results[3]['success'] == true) {
          final appts = results[3]['appointments'];
          _todayAppointments = appts is List ? appts : [];
        }
      });
      }
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

    // Doctor home screen
    if (auth.role == 'D') {
      return _buildDoctorHome(auth);
    }

    // Male patient → dedicated blue home
    if (auth.gender == 'M') {
      return _buildMaleHome(auth);
    }

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(showImage: true, imageOpacity: 0.10),
          const FloatingParticles(particleCount: 22, maxOpacity: 0.25),
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
                      if (_todayAppointments.isNotEmpty) ...[
                        _buildAppointmentsSection(),
                        const SizedBox(height: 16),
                      ],
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

  // ── APPOINTMENTS SECTION ──────────────────────────────────────────
  Widget _buildAppointmentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Iconsax.calendar, color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text("Rendez-vous d'aujourd'hui", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 10),
          ..._todayAppointments.asMap().entries.map((e) {
            final appt = e.value as Map<String, dynamic>;
            final doctor = appt['doctor'] as Map<String, dynamic>?;
            final doctorName = doctor != null
                ? '${doctor['user']?['first_name'] ?? ''} ${doctor['user']?['last_name'] ?? ''}'.trim()
                : 'Médecin';
            final dateStr = appt['appointment_date']?.toString() ?? '';
            final date = DateTime.tryParse(dateStr);
            final timeStr = date != null
                ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                : '--:--';
            final status = appt['status']?.toString() ?? 'PENDING';
            final Color statusColor = status == 'CONFIRMED'
                ? AppColors.success
                : status == 'CANCELLED'
                    ? AppColors.error
                    : AppColors.warning;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withAlpha(100)),
                boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Iconsax.calendar_tick, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr. $doctorName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                        if ((appt['reason']?.toString() ?? '').isNotEmpty)
                          Text(appt['reason'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                        child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (550 + e.key * 100).ms).slideY(begin: 0.1);
          }),
        ],
      ),
    );
  }

  // ── MOTIVATIONAL CARD ───────────────────────────────────────────────
  Widget _buildMotivationalCard() {
    final messages = [
      'Vous êtes incroyable ! Chaque jour compte !',
      'Prenez soin de vous et de votre bébé',
      'Vous faites un travail extraordinaire',
      'Votre santé est notre priorité',
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Iconsax.heart, color: AppColors.primary, size: 28),
            )
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
            children: List.generate(4, (_) => Expanded(
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
    IconData greetIcon;
    Color greetColor;
    if (hour < 12) {
      greeting = 'Bonjour';
      greetIcon = Iconsax.sun_1;
      greetColor = Colors.orange;
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
      greetIcon = Iconsax.cloud_sunny;
      greetColor = Colors.amber;
    } else {
      greeting = 'Bonsoir';
      greetIcon = Iconsax.moon;
      greetColor = Colors.indigo;
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
                        Icon(greetIcon, size: 16, color: greetColor),
                        const SizedBox(width: 4),
                        Text(greeting, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              ),
              _HeaderButton(icon: Iconsax.search_normal, onTap: () => context.push('/medications'), tooltip: 'Rechercher')
                  .animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(width: 8),
              _HeaderButton(icon: Iconsax.hospital, onTap: () => context.push('/doctors'), tooltip: 'Médecins')
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
                          const Icon(Iconsax.heart_add, color: Colors.white70, size: 16),
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
                  child: const Icon(Iconsax.arrow_right_3, color: Colors.white, size: 14),
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
                        const Icon(Iconsax.clock, color: Colors.white, size: 12),
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
    switch (level) {
      case 'HIGH':
        riskColor = AppColors.riskHigh; riskIcon = Iconsax.warning_2; riskLabel = 'Risque élevé'; break;
      case 'MEDIUM':
        riskColor = AppColors.riskMedium; riskIcon = Iconsax.warning_2; riskLabel = 'Risque modéré'; break;
      default:
        riskColor = AppColors.riskLow; riskIcon = Iconsax.tick_circle; riskLabel = 'Risque faible';
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
            child: Icon(riskIcon, size: 24, color: riskColor),
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
              const Icon(Iconsax.flash_1, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              const Text('Actions rapides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ).animate().fadeIn(delay: 50.ms),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _QuickActionCard(icon: Iconsax.ruler, label: 'Nouvelle\nmesure', color: AppColors.primary, onTap: () => context.push('/add-measurement')).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(icon: Iconsax.calendar, label: 'Rendez-\nvous', color: AppColors.accentDark, onTap: () => context.push('/appointments')).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(icon: Iconsax.health, label: 'médicaments', color: AppColors.accent, onTap: () => context.push('/medications')).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(icon: Iconsax.watch, label: 'Montre\nconnect', color: AppColors.warning, onTap: () => context.push('/smartwatch')).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)),
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
                  const Icon(Iconsax.chart_2, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  const Text('Dernières mesures', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.go('/measurements'),
                icon: const Text('Voir tout', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                label: const Icon(Iconsax.arrow_right_3, size: 12, color: AppColors.primary),
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
      _MeasureData(icon: Iconsax.weight, label: 'Poids', value: '${data['weight'] ?? '--'}', unit: 'kg', color: AppColors.primary),
      _MeasureData(icon: Iconsax.chart_2, label: 'IMC', value: '${data['bmi'] ?? '--'}', unit: '', color: AppColors.accent),
      _MeasureData(icon: Iconsax.drop, label: 'Glycémie',
          value: data['glycemia_informations'] != null ? '${data['glycemia_informations']['value1']}' : '--',
          unit: data['glycemia_informations'] != null ? '${data['glycemia_informations']['unit'] ?? ''}' : '', color: AppColors.info),
      _MeasureData(icon: Iconsax.heart, label: 'Tension',
          value: data['blood_pressure'] != null ? '${data['blood_pressure']['value1']}/${data['blood_pressure']['value2']}' : '--',
          unit: 'mmHg', color: AppColors.error),
      _MeasureData(icon: Iconsax.activity, label: 'Rythme', value: data['heart_rate'] != null ? '${data['heart_rate']['value1']}' : '--', unit: 'bpm', color: AppColors.primaryDark),
      _MeasureData(icon: Iconsax.health, label: 'Temp.', value: data['body_temp'] != null ? '${data['body_temp']['value1']}' : '--', unit: '°C', color: AppColors.warning),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Iconsax.ruler, size: 48, color: AppColors.primary),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.05, end: 0.05, duration: 2000.ms),
          const SizedBox(height: 12),
          const Text('Aucune mesure enregistrée', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Ajoutez vos premières mesures pour\nsuivre votre santé', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-measurement'),
            icon: const Icon(Iconsax.add_circle, size: 18),
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
            const Icon(Iconsax.close_circle, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? 'Erreur', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Iconsax.refresh_2, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(160, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().shake(delay: 300.ms, hz: 2, offset: const Offset(4, 0));
  }

  // ══════════════════════════════════════════════════════════════════
  // ── MALE HOME SCREEN (blue theme, no pregnancy / menstrual content)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMaleHome(AuthState auth) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // Animated blue background
          _MaleAnimatedBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: _maleBlue,
              child: _loading
                  ? _buildMaleShimmer()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMaleHeader(auth),
                          if (_error != null)
                            _buildMaleErrorBanner()
                          else ...[
                            const SizedBox(height: 8),
                            _buildMaleStatsRow(),
                            const SizedBox(height: 20),
                            _buildMaleQuickActions(),
                            const SizedBox(height: 24),
                            _buildMaleMeasurementsSection(),
                            const SizedBox(height: 16),
                            if (_todayAppointments.isNotEmpty) ...[
                              _buildMaleAppointmentsSection(),
                              const SizedBox(height: 16),
                            ],
                            _buildMaleMotivationalCard(),
                          ],
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Male Header ───────────────────────────────────────────────────
  Widget _buildMaleHeader(AuthState auth) {
    final name = auth.name ?? 'Utilisateur';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    final greetIcon = hour < 12 ? Iconsax.sun_1 : hour < 18 ? Iconsax.cloud_sunny : Iconsax.moon;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: _maleBlue.withAlpha(100), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _breatheController,
                builder: (context, _) {
                  final s = 1.0 + _breatheController.value * 0.05;
                  return Transform.scale(
                    scale: s,
                    child: Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withAlpha(60), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(greetIcon, size: 14, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(greeting, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Iconsax.shield_tick, size: 12, color: Colors.white70),
                          SizedBox(width: 4),
                          Text('Suivi santé actif', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              ),
              _MaleHeaderBtn(icon: Iconsax.notification, onTap: () => context.push('/alerts'), color: _maleBlueLight)
                  .animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(width: 8),
              _MaleHeaderBtn(icon: Iconsax.hospital, onTap: () => context.push('/doctors'), color: _maleTeal)
                  .animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 16),
          // Blue health pulse line
          Row(
            children: [
              const Icon(Iconsax.activity, color: Colors.white60, size: 14),
              const SizedBox(width: 6),
              const Text('Bonne santé commence par un suivi régulier', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  // ── Male Stats Row ─────────────────────────────────────────────────
  Widget _buildMaleStatsRow() {
    final data = _latestData;
    final hrValue = data?['heart_rate'] != null ? '${data!['heart_rate']['value1']} bpm' : '--';
    final bpValue = data?['blood_pressure'] != null
        ? '${data!['blood_pressure']['value1']}/${data['blood_pressure']['value2']}'
        : '--';
    final tempValue = data?['body_temp'] != null ? '${data!['body_temp']['value1']}°C' : '--';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _MaleStatCard(icon: Iconsax.activity, label: 'Rythme\ncardiac', value: hrValue, color: _maleBlueLight)),
          const SizedBox(width: 10),
          Expanded(child: _MaleStatCard(icon: Iconsax.heart, label: 'Tension\nartérielle', value: bpValue, color: const Color(0xFFEF5350))),
          const SizedBox(width: 10),
          Expanded(child: _MaleStatCard(icon: Iconsax.health, label: 'Tempéra-\nture', value: tempValue, color: _maleTeal)),
        ],
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
    );
  }

  // ── Male Quick Actions ──────────────────────────────────────────────
  Widget _buildMaleQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Iconsax.flash_1, color: Color(0xFF1565C0), size: 20),
              SizedBox(width: 6),
              Text('Actions rapides', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MaleActionCard(icon: Iconsax.ruler, label: 'Nouvelle\nmesure', color: _maleBlue, onTap: () => context.push('/add-measurement')).animate().fadeIn(delay: 120.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 450.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 10),
              Expanded(child: _MaleActionCard(icon: Iconsax.calendar, label: 'Rendez-\nvous', color: _maleTeal, onTap: () => context.push('/appointments')).animate().fadeIn(delay: 170.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 450.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 10),
              Expanded(child: _MaleActionCard(icon: Iconsax.health, label: 'Médica-\nments', color: _maleBlueLight, onTap: () => context.push('/medications')).animate().fadeIn(delay: 220.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 450.ms, curve: Curves.easeOutBack)),
              const SizedBox(width: 10),
              Expanded(child: _MaleActionCard(icon: Iconsax.watch, label: 'Montre\nSmart', color: const Color(0xFF5C6BC0), onTap: () => context.push('/smartwatch')).animate().fadeIn(delay: 270.ms).slideY(begin: 0.2).scale(begin: const Offset(0.8, 0.8), duration: 450.ms, curve: Curves.easeOutBack)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Male Measurements Section ──────────────────────────────────────
  Widget _buildMaleMeasurementsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Iconsax.chart_2, color: Color(0xFF1565C0), size: 20),
                SizedBox(width: 6),
                Text('Dernières mesures', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ]),
              TextButton.icon(
                onPressed: () => context.go('/measurements'),
                icon: const Text('Voir tout', style: TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.w600)),
                label: const Icon(Iconsax.arrow_right_3, size: 12, color: Color(0xFF1565C0)),
              ),
            ],
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 8),
          if (_latestData != null) _buildMaleMeasurementsGrid() else _buildMaleEmptyMeasurements(),
        ],
      ),
    );
  }

  Widget _buildMaleMeasurementsGrid() {
    final d = _latestData!;
    final items = <_MeasureData>[
      _MeasureData(icon: Iconsax.weight, label: 'Poids', value: '${d['weight'] ?? '--'}', unit: 'kg', color: _maleBlue),
      _MeasureData(icon: Iconsax.chart_2, label: 'IMC', value: '${d['bmi'] ?? '--'}', unit: '', color: const Color(0xFF5C6BC0)),
      _MeasureData(icon: Iconsax.drop, label: 'Glycémie', value: d['glycemia_informations'] != null ? '${d['glycemia_informations']['value1']}' : '--', unit: d['glycemia_informations'] != null ? '${d['glycemia_informations']['unit'] ?? ''}' : '', color: AppColors.info),
      _MeasureData(icon: Iconsax.heart, label: 'Tension', value: d['blood_pressure'] != null ? '${d['blood_pressure']['value1']}/${d['blood_pressure']['value2']}' : '--', unit: 'mmHg', color: AppColors.error),
      _MeasureData(icon: Iconsax.activity, label: 'Rythme', value: d['heart_rate'] != null ? '${d['heart_rate']['value1']}' : '--', unit: 'bpm', color: _maleBlueLight),
      _MeasureData(icon: Iconsax.health, label: 'Temp.', value: d['body_temp'] != null ? '${d['body_temp']['value1']}' : '--', unit: '°C', color: _maleTeal),
    ];
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Expanded(child: _MeasureCard(data: items[i]).animate().fadeIn(delay: (100 * (i ~/ 2 + 1) + 400).ms).slideY(begin: 0.15)),
              const SizedBox(width: 12),
              Expanded(child: i + 1 < items.length
                  ? _MeasureCard(data: items[i + 1]).animate().fadeIn(delay: (100 * (i ~/ 2 + 1) + 450).ms).slideY(begin: 0.15)
                  : const SizedBox.shrink()),
            ]),
          ),
      ],
    );
  }

  Widget _buildMaleEmptyMeasurements() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _maleBluePale,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _maleBlue.withAlpha(40)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _maleBlue.withAlpha(25), borderRadius: BorderRadius.circular(20)),
            child: Icon(Iconsax.ruler, size: 48, color: _maleBlue),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.05, end: 0.05, duration: 2000.ms),
          const SizedBox(height: 12),
          Text('Aucune mesure enregistrée', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _maleBlue)),
          const SizedBox(height: 4),
          const Text('Ajoutez vos premières mesures\npour suivre votre santé', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-measurement'),
            icon: const Icon(Iconsax.add_circle, size: 18),
            label: const Text('Ajouter une mesure'),
            style: ElevatedButton.styleFrom(backgroundColor: _maleBlue, minimumSize: const Size(200, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMaleAppointmentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Iconsax.calendar, color: Color(0xFF1565C0), size: 20),
            SizedBox(width: 6),
            Text("Rendez-vous d'aujourd'hui", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 10),
          ..._todayAppointments.asMap().entries.map((e) {
            final appt = e.value as Map<String, dynamic>;
            final doctor = appt['doctor'] as Map<String, dynamic>?;
            final doctorName = doctor != null ? '${doctor['user']?['first_name'] ?? ''} ${doctor['user']?['last_name'] ?? ''}'.trim() : 'Médecin';
            final dateStr = appt['appointment_date']?.toString() ?? '';
            final date = DateTime.tryParse(dateStr);
            final timeStr = date != null ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : '--:--';
            final status = appt['status']?.toString() ?? 'PENDING';
            final Color statusColor = status == 'CONFIRMED' ? AppColors.success : status == 'CANCELLED' ? AppColors.error : AppColors.warning;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: _maleBlue.withAlpha(120), width: 4)),
                boxShadow: [BoxShadow(color: _maleBlue.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _maleBlue.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(Iconsax.calendar_tick, color: _maleBlue, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. $doctorName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                  if ((appt['reason']?.toString() ?? '').isNotEmpty)
                    Text(appt['reason'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(timeStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _maleBlue)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600))),
                ]),
              ]),
            ).animate().fadeIn(delay: (550 + e.key * 100).ms).slideY(begin: 0.1);
          }),
        ],
      ),
    );
  }

  Widget _buildMaleMotivationalCard() {
    final messages = [
      'La santé est la vraie richesse — prenez soin de vous',
      'Un suivi régulier est la clé d\'une bonne santé',
      'Votre bien-être est notre priorité absolue',
      'Chaque mesure vous rapproche d\'une meilleure santé',
    ];
    final msg = messages[DateTime.now().day % messages.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_maleBlue.withAlpha(20), _maleBluePale],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _maleBlue.withAlpha(40)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _maleBlue.withAlpha(20), borderRadius: BorderRadius.circular(14)),
            child: Icon(Iconsax.shield_tick, color: _maleBlue, size: 28),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 2000.ms, curve: Curves.easeInOut),
          const SizedBox(width: 14),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _maleBlueDark, height: 1.4, fontStyle: FontStyle.italic))),
        ]),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15);
  }

  Widget _buildMaleShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 140, decoration: BoxDecoration(color: _maleBluePale, borderRadius: BorderRadius.circular(28)))
            .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
        const SizedBox(height: 16),
        Row(children: List.generate(3, (_) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 80, decoration: BoxDecoration(color: _maleBluePale, borderRadius: BorderRadius.circular(16))))))
            .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
        const SizedBox(height: 16),
        Row(children: List.generate(4, (_) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), height: 90, decoration: BoxDecoration(color: _maleBluePale, borderRadius: BorderRadius.circular(16))))))
            .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
        const SizedBox(height: 16),
        ...List.generate(3, (_) => Container(margin: const EdgeInsets.only(bottom: 12), height: 80, decoration: BoxDecoration(color: _maleBluePale, borderRadius: BorderRadius.circular(16))))
            .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white38),
      ]),
    );
  }

  Widget _buildMaleErrorBanner() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.error.withAlpha(15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.error.withAlpha(51))),
        child: Column(children: [
          const Icon(Iconsax.close_circle, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error ?? 'Erreur', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Iconsax.refresh_2, size: 18),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: _maleBlue, minimumSize: const Size(160, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ]),
      ),
    ).animate().fadeIn().shake(delay: 300.ms, hz: 2, offset: const Offset(4, 0));
  }

  // ── DOCTOR HOME ───────────────────────────────────────────────────
  Widget _buildDoctorHome(AuthState auth) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(showImage: true, imageOpacity: 0.10),
          const FloatingParticles(particleCount: 12, maxOpacity: 0.15),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          radius: 30,
                          child: Icon(Iconsax.user, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. ${auth.name ?? ''}',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Tableau de bord médecin',
                                  style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1),
                  const SizedBox(height: 24),
                  Text('Actions rapides',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _doctorActionCard('Rendez-vous', Iconsax.calendar, AppColors.primary,
                          () => context.go('/appointments')),
                      _doctorActionCard('Médecins', Iconsax.people, AppColors.secondary,
                          () => context.push('/doctors')),
                      _doctorActionCard('Profil', Iconsax.user, AppColors.success,
                          () => context.go('/profile')),
                      _doctorActionCard('Paramètres', Iconsax.setting_2, Colors.grey,
                          () => context.push('/settings')),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
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
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

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
              Icon(widget.icon, size: 28, color: widget.color),
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
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _MeasureData({required this.icon, required this.label, required this.value, required this.unit, required this.color});
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
            child: Center(child: Icon(data.icon, size: 18, color: data.color)),
          ),
          const SizedBox(height: 12),
          Text(data.label, style: const TextStyle(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: Text(data.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              if (data.unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(data.unit, style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w500)),
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

// ─── Male Animated Background ──────────────────────────────────────────
class _MaleAnimatedBackground extends StatefulWidget {
  @override
  State<_MaleAnimatedBackground> createState() => _MaleAnimatedBackgroundState();
}
class _MaleAnimatedBackgroundState extends State<_MaleAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFFE3F2FD), const Color(0xFFBBDEFB), _anim.value)!,
              Color.lerp(const Color(0xFFF0F4FF), const Color(0xFFE8EAF6), _anim.value)!,
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─── Male Header Button ────────────────────────────────────────────────
class _MaleHeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _MaleHeaderBtn({required this.icon, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Male Stat Card ────────────────────────────────────────────────────
class _MaleStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MaleStatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.2)),
        ],
      ),
    );
  }
}

// ─── Male Action Card ──────────────────────────────────────────────────
class _MaleActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MaleActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  State<_MaleActionCard> createState() => _MaleActionCardState();
}
class _MaleActionCardState extends State<_MaleActionCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color.withAlpha(25), widget.color.withAlpha(10)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withAlpha(60)),
            boxShadow: _pressed ? [] : [BoxShadow(color: widget.color.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Icon(widget.icon, size: 26, color: widget.color),
            const SizedBox(height: 6),
            Text(widget.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.color, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}
