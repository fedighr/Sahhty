// lib/features/home/screens/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/alert_model.dart' as alert_model;
import '../../auth/providers/auth_notifier.dart';
import '../../auth/providers/auth_state.dart';
import '../providers/home_provider.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeNotifierProvider);
    final userName = _extractUserName(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildAppBar(context, ref, userName, homeData.unreadAlerts.length),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: homeData.isLoading
                  ? SliverList(delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      const LoadingShimmer(itemCount: 4),
                    ]))
                  : SliverList(delegate: SliverChildListDelegate([
                      // Alertes critiques
                      if (homeData.unreadAlerts.any((a) => a.isCritical))
                        _AlertsBanner(alerts: homeData.unreadAlerts.where((a) => a.isCritical).toList())
                            .animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),

                      // Carte grossesse
                      if (homeData.activePregnancy != null) ...[
                        const SizedBox(height: 12),
                        _PregnancyCard(pregnancy: homeData.activePregnancy!)
                            .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                      ],

                      // Timeline grossesse
                      if (homeData.activePregnancy != null) ...[
                        const SizedBox(height: 20),
                        _PregnancyTimeline(pregnancy: homeData.activePregnancy!)
                            .animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
                      ],

                      // Accès rapide
                      const SizedBox(height: 24),
                      _sectionTitle('Accès rapide'),
                      const SizedBox(height: 12),
                      _QuickActionsGrid()
                          .animate().fadeIn(delay: 200.ms),

                      // Indicateurs de santé
                      const SizedBox(height: 24),
                      _sectionTitle('Indicateurs de santé'),
                      const SizedBox(height: 12),
                      _HealthIndicatorsCard(
                        measurements: homeData.recentMeasurements,
                        risk: homeData.latestRisk,
                        patient: homeData.patient,
                      ).animate().fadeIn(delay: 250.ms),

                      // Alertes
                      if (homeData.unreadAlerts.where((a) => !a.isCritical).isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle('Notifications'),
                        const SizedBox(height: 12),
                        ...homeData.unreadAlerts
                            .where((a) => !a.isCritical)
                            .take(3)
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _AlertCard(alert: a),
                                )),
                      ],

                      // Prochain rendez-vous
                      const SizedBox(height: 24),
                      _sectionTitle('Prochains rendez-vous'),
                      const SizedBox(height: 12),
                      if (homeData.upcomingAppointments.isEmpty)
                        _EmptyAppointmentCard()
                            .animate().fadeIn(delay: 350.ms)
                      else
                        ...homeData.upcomingAppointments.take(2).map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AppointmentCard(appointment: a),
                            )),

                      const SizedBox(height: 32),
                    ])),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(),
    );
  }

  String _extractUserName(WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess) return authState.name;
    return '';
  }

  Widget _sectionTitle(String t) => Row(
        children: [
          Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('Voir tout', style: TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
        ],
      );

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref, String userName, int alertCount) {
    final greeting = _getGreeting();
    final displayName = userName.isNotEmpty ? userName.split(' ').first : 'Chérie';

    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: const Center(
                  child: Text('👩‍🍼', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$greeting 💕',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      onPressed: () => context.push(AppRoutes.alerts),
                    ),
                  ),
                  if (alertCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            alertCount > 9 ? '9+' : '$alertCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

// ─── Pregnancy Card ────────────────────────────────────────────────────────────

class _PregnancyCard extends StatelessWidget {
  final Pregnancy pregnancy;
  const _PregnancyCard({required this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final week = pregnancy.currentWeek ?? 0;
    final days = pregnancy.daysRemaining ?? 0;
    final trimester = pregnancy.trimester;
    final babySize = pregnancy.babySize;
    final progress = week / 40;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8BBD0), Color(0xFFFFCDD2), Color(0xFFFFEBEE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF8BBD0).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🤰 ${trimester}${trimester == 1 ? "er" : "ème"} trimestre',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFAD1457)),
                ),
              ),
              const Spacer(),
              Text(
                '$days jours restants',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFAD1457).withOpacity(0.8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ma Grossesse',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF880E4F)),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Color(0xFFAD1457)),
                        children: [
                          const TextSpan(text: 'Semaine '),
                          TextSpan(
                            text: '$week',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF880E4F)),
                          ),
                          const TextSpan(text: ' / 40'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bébé: $babySize',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFAD1457)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getBabyEmoji(week),
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC407A), Color(0xFFAD1457)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (pregnancy.dueDate != null)
            Text(
              'Date prévue: ${_formatDate(pregnancy.dueDate!)}',
              style: TextStyle(fontSize: 12, color: const Color(0xFFAD1457).withOpacity(0.7)),
            ),
        ],
      ),
    );
  }

  String _getBabyEmoji(int week) {
    if (week < 8) return '🫧';
    if (week < 14) return '👶';
    if (week < 28) return '🤱';
    return '👶🏻';
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(d);
    } catch (_) {
      return date;
    }
  }
}

// ─── Pregnancy Timeline ────────────────────────────────────────────────────────

class _PregnancyTimeline extends StatelessWidget {
  final Pregnancy pregnancy;
  const _PregnancyTimeline({required this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final week = pregnancy.currentWeek ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parcours de grossesse', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _TrimesterBlock(label: '1er trim.', weeks: '1-12', isCurrent: week >= 1 && week <= 12, isCompleted: week > 12),
              _TrimesterConnector(isCompleted: week > 12),
              _TrimesterBlock(label: '2ème trim.', weeks: '13-27', isCurrent: week >= 13 && week <= 27, isCompleted: week > 27),
              _TrimesterConnector(isCompleted: week > 27),
              _TrimesterBlock(label: '3ème trim.', weeks: '28-40', isCurrent: week >= 28, isCompleted: false),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMilestone(week),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFAD1457)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMilestone(int week) {
    if (week < 6) return 'Le cœur de bébé commence à battre !';
    if (week < 10) return 'Les organes principaux se forment.';
    if (week < 14) return 'Fin du 1er trimestre, les nausées diminuent.';
    if (week < 18) return 'Bébé commence à bouger doucement.';
    if (week < 22) return 'Vous pouvez sentir les premiers mouvements !';
    if (week < 28) return 'Bébé entend votre voix et réagit aux sons.';
    if (week < 32) return 'Bébé prend du poids et se prépare.';
    if (week < 36) return 'Bébé se positionne tête en bas.';
    if (week < 39) return 'Bébé est presque prêt pour la naissance !';
    return 'C\'est le moment ! Bébé peut arriver à tout instant.';
  }
}

class _TrimesterBlock extends StatelessWidget {
  final String label, weeks;
  final bool isCurrent, isCompleted;
  const _TrimesterBlock({required this.label, required this.weeks, required this.isCurrent, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isCurrent
                      ? const Color(0xFFEC407A)
                      : AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.child_care_rounded,
              color: (isCompleted || isCurrent) ? Colors.white : AppColors.textHint,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: isCurrent ? const Color(0xFFEC407A) : AppColors.textSecondary)),
          Text(weeks, style: TextStyle(fontSize: 10, color: isCurrent ? const Color(0xFFEC407A) : AppColors.textHint)),
        ],
      ),
    );
  }
}

class _TrimesterConnector extends StatelessWidget {
  final bool isCompleted;
  const _TrimesterConnector({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 3,
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success : AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─── Quick Actions Grid ────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  static const _actions = [
    (Icons.pregnant_woman_rounded, 'Ma Grossesse', Color(0xFFEC407A), AppRoutes.pregnancyDetail),
    (Icons.monitor_heart_outlined, 'Mesures', Color(0xFF1565C0), AppRoutes.measurements),
    (Icons.calendar_month_outlined, 'Rendez-vous', Color(0xFF00ACC1), AppRoutes.appointmentsList),
    (Icons.medication_outlined, 'Médicaments', Color(0xFF7C4DFF), AppRoutes.medicationsList),
    (Icons.folder_outlined, 'Dossier médical', Color(0xFFFF7043), AppRoutes.medicalFiles),
    (Icons.person_outline_rounded, 'Mon Profil', Color(0xFF26A69A), AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: _actions.map((a) => _ActionTile(icon: a.$1, label: a.$2, color: a.$3, route: a.$4)).toList(),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Health Indicators Card ────────────────────────────────────────────────────

class _HealthIndicatorsCard extends StatelessWidget {
  final List<Measurement> measurements;
  final RiskAssessment? risk;
  final dynamic patient;
  const _HealthIndicatorsCard({required this.measurements, this.risk, this.patient});

  @override
  Widget build(BuildContext context) {
    final bp = measurements.where((m) => m.type == 'BLOOD_PRESSURE').firstOrNull;
    final weight = measurements.where((m) => m.type == 'WEIGHT').firstOrNull;
    final glycemia = measurements.where((m) => m.type == 'GLYCEMIA').firstOrNull;
    final heartRate = measurements.where((m) => m.type == 'HEART_RATE').firstOrNull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (risk != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _riskColor(risk!.globalRiskLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _riskColor(risk!.globalRiskLevel).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    risk!.isHighRisk ? Icons.warning_rounded : Icons.shield_outlined,
                    color: _riskColor(risk!.globalRiskLevel),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Risque ${_riskLabel(risk!.globalRiskLevel)} — ${risk!.globalRiskPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _riskColor(risk!.globalRiskLevel)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              _MetricTile(icon: Icons.favorite_rounded, label: 'Tension', value: bp?.displayValue ?? '--/--', unit: 'mmHg', color: bp != null && bp.isAbnormal ? AppColors.error : const Color(0xFFE91E63), isAbnormal: bp?.isAbnormal ?? false),
              const SizedBox(width: 12),
              _MetricTile(icon: Icons.scale_rounded, label: 'Poids', value: weight?.displayValue ?? '--', unit: 'kg', color: const Color(0xFF00ACC1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricTile(icon: Icons.water_drop_rounded, label: 'Glycémie', value: glycemia?.displayValue ?? '--', unit: 'g/L', color: glycemia != null && glycemia.isAbnormal ? AppColors.error : const Color(0xFF7C4DFF), isAbnormal: glycemia?.isAbnormal ?? false),
              const SizedBox(width: 12),
              _MetricTile(icon: Icons.monitor_heart_rounded, label: 'Pouls', value: heartRate?.displayValue ?? '--', unit: 'bpm', color: heartRate != null && heartRate.isAbnormal ? AppColors.error : const Color(0xFFFF7043), isAbnormal: heartRate?.isAbnormal ?? false),
            ],
          ),
        ],
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'HIGH': return AppColors.error;
      case 'MEDIUM': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  String _riskLabel(String level) {
    switch (level) {
      case 'HIGH': return 'Élevé';
      case 'MEDIUM': return 'Modéré';
      default: return 'Faible';
    }
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;
  final bool isAbnormal;
  const _MetricTile({required this.icon, required this.label, required this.value, required this.unit, required this.color, this.isAbnormal = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isAbnormal ? AppColors.errorLight : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: isAbnormal ? Border.all(color: AppColors.error.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isAbnormal ? AppColors.error : AppColors.textPrimary))),
                      const SizedBox(width: 2),
                      Text(unit, style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                    ],
                  ),
                  if (isAbnormal)
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 10, color: AppColors.error),
                        const SizedBox(width: 2),
                        const Flexible(child: Text('Anormal', style: TextStyle(fontSize: 9, color: AppColors.error, fontWeight: FontWeight.w600))),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Alerts ────────────────────────────────────────────────────────────────────

class _AlertsBanner extends StatelessWidget {
  final List<alert_model.Alert> alerts;
  const _AlertsBanner({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${alerts.length} alerte${alerts.length > 1 ? 's' : ''} critique${alerts.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
                const SizedBox(height: 2),
                Text(alerts.first.message, style: TextStyle(fontSize: 11, color: AppColors.error.withOpacity(0.8)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.error),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final alert_model.Alert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isWarning = alert.isWarning;
    final color = isWarning ? AppColors.warning : AppColors.primary;
    final bgColor = isWarning ? const Color(0xFFFFF8E1) : const Color(0xFFE3F2FD);
    final icon = isWarning ? Icons.info_outline_rounded : Icons.notifications_outlined;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text(alert.message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment Card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(appointment.appointmentDate);
    final isConfirmed = appointment.isConfirmed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isConfirmed ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(date != null ? DateFormat('dd').format(date) : '--', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isConfirmed ? AppColors.success : AppColors.warning)),
                Text(date != null ? DateFormat('MMM', 'fr_FR').format(date).toUpperCase() : '--', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isConfirmed ? AppColors.success : AppColors.warning)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (appointment.doctorName != null)
                  Text(appointment.doctorName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(date != null ? DateFormat('HH:mm').format(date) : '--:--', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: isConfirmed ? AppColors.successLight : const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(6)),
                      child: Text(appointment.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isConfirmed ? AppColors.success : AppColors.warning)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }
}

class _EmptyAppointmentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined, color: AppColors.textHint, size: 36),
          const SizedBox(height: 10),
          const Text('Aucun rendez-vous prévu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Prenez rendez-vous avec votre médecin', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.appointmentsList),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Prendre rendez-vous', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Accueil', isActive: true, onTap: () {}),
              _NavItem(icon: Icons.monitor_heart_outlined, label: 'Mesures', onTap: () => context.push(AppRoutes.measurements)),
              _NavItem(icon: Icons.pregnant_woman_rounded, label: 'Grossesse', onTap: () => context.push(AppRoutes.pregnancyDetail), isHighlighted: true),
              _NavItem(icon: Icons.calendar_month_outlined, label: 'RDV', onTap: () => context.push(AppRoutes.appointmentsList)),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', onTap: () => context.push(AppRoutes.profile)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isHighlighted;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, this.isActive = false, this.isHighlighted = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isHighlighted) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEC407A), Color(0xFFF8BBD0)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFFEC407A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.pregnant_woman_rounded, color: Colors.white, size: 26),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : AppColors.textHint, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? AppColors.primary : AppColors.textHint)),
        ],
      ),
    );
  }
}
