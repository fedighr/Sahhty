// lib/features/home/screens/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../data/models/measurement_model.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../auth/providers/auth_state.dart';
import '../providers/home_provider.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeNotifierProvider);
    final userName = _extractUserName(ref, homeData.patient);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _HomeAppBar(
              userName: userName,
              alertCount: homeData.unreadAlerts.length,
              onLogout: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
            SliverToBoxAdapter(
              child: homeData.isLoading
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 120),
                      child: LoadingShimmer(itemCount: 5),
                    )
                  : homeData.error != null
                      ? _HomeError(
                          message: homeData.error!,
                          onRetry: () => ref.read(homeNotifierProvider.notifier).refresh(),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (homeData.unreadAlerts.isNotEmpty)
                                _AlertsSummaryCard(alertCount: homeData.unreadAlerts.length)
                                    .animate().fadeIn(duration: 250.ms),
                              if (homeData.unreadAlerts.isNotEmpty) const SizedBox(height: 16),
                              if (homeData.activePregnancy != null)
                                _PregnancyHeroCard(pregnancy: homeData.activePregnancy!)
                                    .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08)
                              else
                                _NoPregnancyCard()
                                    .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08),
                              const SizedBox(height: 20),
                              _SectionHeader(
                                title: 'Mes repères santé',
                                actionLabel: 'Mes mesures',
                                onTap: () => context.push(AppRoutes.measurements),
                              ),
                              const SizedBox(height: 12),
                              _HealthSummaryGrid(
                                measurements: homeData.recentMeasurements,
                                risk: homeData.latestRisk,
                                patient: homeData.patient,
                              ).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 24),
                              const _SectionHeader(title: 'Accès rapide'),
                              const SizedBox(height: 12),
                              const _QuickActionsGrid().animate().fadeIn(delay: 150.ms),
                              const SizedBox(height: 24),
                              _SectionHeader(
                                title: 'Conseils du jour',
                                actionLabel: homeData.activePregnancy != null ? 'Ma grossesse' : null,
                                onTap: homeData.activePregnancy != null
                                    ? () => context.push(AppRoutes.pregnancyDetail)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _TipsCard(pregnancy: homeData.activePregnancy)
                                  .animate().fadeIn(delay: 200.ms),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }

  String _extractUserName(WidgetRef ref, Patient? patient) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is AuthSuccess && authState.name.trim().isNotEmpty) {
      return authState.name.trim();
    }
    return patient != null ? 'Patiente' : 'Chérie';
  }
}

class _HomeAppBar extends StatelessWidget {
  final String userName;
  final int alertCount;
  final Future<void> Function() onLogout;
  const _HomeAppBar({
    required this.userName,
    required this.alertCount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();
    final firstName = userName.split(' ').first;

    return SliverAppBar(
      expandedHeight: 160,
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
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 22),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: const Center(child: Text('🤰', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting ✨',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Votre suivi santé et grossesse, en un coup d’œil',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _TopIconButton(
                icon: Icons.notifications_outlined,
                badge: alertCount,
                onTap: () => context.push(AppRoutes.alerts),
              ),
              const SizedBox(width: 8),
              _TopIconButton(
                icon: Icons.logout_rounded,
                badge: 0,
                onTap: () => onLogout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _TopIconButton({required this.icon, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white.withValues(alpha: 0.96)),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(color: Color(0xFFFF5A5F), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                badge > 9 ? '9+' : '$badge',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _AlertsSummaryCard extends StatelessWidget {
  final int alertCount;
  const _AlertsSummaryCard({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.alerts),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFFFD9D9),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.error),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Des alertes demandent votre attention', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                  SizedBox(height: 2),
                  Text('Ouvrez vos notifications pour voir les conseils ou alertes médicales.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}

class _PregnancyHeroCard extends StatelessWidget {
  final Pregnancy pregnancy;
  const _PregnancyHeroCard({required this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final week = pregnancy.currentWeek ?? 0;
    final daysRemaining = pregnancy.daysRemaining ?? 0;
    final progress = (week / 40).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => context.push(AppRoutes.pregnancyDetail),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFFDF2F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Trimestre ${pregnancy.trimester}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFBE185D)),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ma grossesse', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$week',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const TextSpan(
                              text: ' semaines',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pregnancy.babySize,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('👶', style: TextStyle(fontSize: 38))),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFEC4899)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniStat(label: 'Jours restants', value: '$daysRemaining'),
                const SizedBox(width: 12),
                _MiniStat(label: 'Terme prévu', value: _formatDate(pregnancy.dueDate)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '—';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('dd MMM', 'fr_FR').format(parsed);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _NoPregnancyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.favorite_border_rounded,
      title: 'Aucune grossesse active',
      subtitle: 'Quand votre suivi de grossesse sera disponible, il apparaîtra ici avec vos repères essentiels.',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  const _SectionHeader({required this.title, this.actionLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const Spacer(),
        if (actionLabel != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _HealthSummaryGrid extends StatelessWidget {
  final List<Measurement> measurements;
  final RiskAssessment? risk;
  final Patient? patient;
  const _HealthSummaryGrid({required this.measurements, required this.risk, required this.patient});

  @override
  Widget build(BuildContext context) {
    final bp = _latestOf('BLOOD_PRESSURE');
    final weight = _latestOf('WEIGHT');
    final glycemia = _latestOf('GLYCEMIA');

    return Column(
      children: [
        if (risk != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _riskColor(risk!.globalRiskLevel).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _riskColor(risk!.globalRiskLevel).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: _riskColor(risk!.globalRiskLevel)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Niveau de risque ${_riskLabel(risk!.globalRiskLevel)} • ${risk!.globalRiskPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _riskColor(risk!.globalRiskLevel)),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(child: _MetricCard(title: 'Tension', value: bp?.displayValue ?? '--/--', unit: bp?.displayUnit ?? 'mmHg', icon: Icons.favorite_rounded, color: const Color(0xFFE11D48), abnormal: bp?.isAbnormal ?? false)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(title: 'Poids', value: weight?.displayValue ?? (patient?.weight.toStringAsFixed(1) ?? '--'), unit: weight?.displayUnit ?? 'kg', icon: Icons.scale_rounded, color: const Color(0xFF0891B2))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(title: 'Glycémie', value: glycemia?.displayValue ?? '--', unit: glycemia?.displayUnit ?? 'g/L', icon: Icons.water_drop_rounded, color: const Color(0xFF7C3AED), abnormal: glycemia?.isAbnormal ?? false)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(title: 'IMC', value: patient != null ? patient!.bmi.toStringAsFixed(1) : '--', unit: '', icon: Icons.insights_outlined, color: const Color(0xFF2563EB))),
          ],
        ),
      ],
    );
  }

  Measurement? _latestOf(String type) {
    final filtered = measurements.where((m) => m.type == type);
    if (filtered.isEmpty) return null;
    return filtered.first;
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'HIGH':
        return AppColors.error;
      case 'MEDIUM':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _riskLabel(String level) {
    switch (level) {
      case 'HIGH':
        return 'élevé';
      case 'MEDIUM':
        return 'modéré';
      default:
        return 'faible';
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool abnormal;
  const _MetricCard({required this.title, required this.value, required this.unit, required this.icon, required this.color, this.abnormal = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: abnormal ? AppColors.errorLight : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: abnormal ? Border.all(color: AppColors.error.withValues(alpha: 0.22)) : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text('$value ${unit.trim()}'.trim(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: abnormal ? AppColors.error : AppColors.textPrimary)),
          if (abnormal)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Valeur à surveiller', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.person_outline_rounded, 'Profil', AppRoutes.profile, const Color(0xFF0EA5E9)),
      (Icons.pregnant_woman_rounded, 'Grossesse', AppRoutes.pregnancyDetail, const Color(0xFFEC4899)),
      (Icons.monitor_heart_outlined, 'Mesures', AppRoutes.measurements, const Color(0xFF8B5CF6)),
      (Icons.notifications_none_rounded, 'Alertes', AppRoutes.alerts, const Color(0xFFF97316)),
      (Icons.medical_services_outlined, 'Médecins', AppRoutes.doctorsList, const Color(0xFF14B8A6)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, index) {
        final item = actions[index];
        return InkWell(
          onTap: () => context.push(item.$3),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.$4.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.$1, color: item.$4),
                ),
                const SizedBox(height: 8),
                Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TipsCard extends StatelessWidget {
  final Pregnancy? pregnancy;
  const _TipsCard({this.pregnancy});

  @override
  Widget build(BuildContext context) {
    final tips = pregnancy == null
        ? const [
            'Gardez vos informations de santé à jour dans votre profil.',
            'Surveillez régulièrement votre poids et votre tension.',
            'Consultez rapidement si vous remarquez un symptôme inhabituel.',
          ]
        : _pregnancyTips(pregnancy!.currentWeek ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips
            .map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16, color: AppColors.primary)),
                    Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary))),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<String> _pregnancyTips(int week) {
    if (week <= 12) {
      return [
        'Pensez à votre acide folique et à une bonne hydratation.',
        'Consultez rapidement en cas de saignement, douleur importante ou vomissements sévères.',
        'Reposez-vous et fractionnez les repas si vous avez des nausées.',
      ];
    }
    if (week <= 27) {
      return [
        'Surveillez régulièrement la tension et le poids.',
        'Bougez doucement chaque jour si votre médecin l’autorise.',
        'Préparez vos examens de suivi et vos consultations du trimestre.',
      ];
    }
    return [
      'Surveillez les mouvements du bébé et consultez si vous les sentez moins.',
      'Préparez votre valise et votre projet de naissance sereinement.',
      'Consultez immédiatement en cas de contractions douloureuses, perte des eaux ou saignement.',
    ];
  }
}

class _HomeError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _HomeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: EmptyStateWidget(
        icon: Icons.cloud_off_rounded,
        title: 'Impossible de charger votre accueil',
        subtitle: message,
        actionLabel: 'Réessayer',
        onAction: () => onRetry(),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Accueil', active: true, onTap: () {}),
              _NavItem(icon: Icons.monitor_heart_outlined, label: 'Mesures', onTap: () => context.push(AppRoutes.measurements)),
              _NavItem(icon: Icons.pregnant_woman_rounded, label: 'Grossesse', onTap: () => context.push(AppRoutes.pregnancyDetail)),
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
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.primary : AppColors.textHint),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: active ? AppColors.primary : AppColors.textHint, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}
