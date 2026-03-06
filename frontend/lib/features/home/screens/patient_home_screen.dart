// lib/features/home/screens/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_notifier.dart';

class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _WelcomeBanner().animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _sectionTitle('Accès rapide'),
              const SizedBox(height: 12),
              _QuickActionsGrid().animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              _sectionTitle('Votre santé'),
              const SizedBox(height: 12),
              _HealthSummaryCard().animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              _sectionTitle('Prochains rendez-vous'),
              const SizedBox(height: 12),
              _AppointmentPlaceholder().animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) => SliverAppBar(
    expandedHeight: 120, floating: true, pinned: true,
    backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('Bonjour 👋', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const Text('Comment vous sentez-vous ?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ])),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ]),
      ),
    ),
  );
}

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Votre santé en premier', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Suivez votre santé\nquotidiennement', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Text('Compléter mon profil →', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ])),
      const Icon(Icons.favorite_rounded, color: Colors.white, size: 64),
    ]),
  );
}

class _QuickActionsGrid extends StatelessWidget {
  static const _actions = [
    (Icons.personal_injury_outlined,    'Mon dossier',     AppColors.primary),
    (Icons.calendar_month_outlined,     'Rendez-vous',     Color(0xFF00ACC1)),
    (Icons.medication_outlined,         'Médicaments',     Color(0xFF7C4DFF)),
    (Icons.monitor_heart_outlined,      'Constantes',      Color(0xFFE91E63)),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12, mainAxisSpacing: 0,
    childAspectRatio: 0.8,
    children: _actions.map((a) => _ActionTile(icon: a.$1, label: a.$2, color: a.$3)).toList(),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 56, height: 56,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: color, size: 26),
    ),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary), textAlign: TextAlign.center),
  ]);
}

class _HealthSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Résumé de santé', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 16),
      Row(children: [
        _HealthMetric(label: 'Taille', value: '-- cm', icon: Icons.height_rounded, color: AppColors.primary),
        _HealthMetric(label: 'Poids', value: '-- kg', icon: Icons.scale_outlined, color: const Color(0xFF00ACC1)),
        _HealthMetric(label: 'Groupe', value: '--', icon: Icons.bloodtype_outlined, color: const Color(0xFFE91E63)),
      ]),
      const SizedBox(height: 16),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Text('Complétez votre profil pour voir vos données', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    ]),
  );
}

class _HealthMetric extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _HealthMetric({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
    const SizedBox(height: 6),
    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
  ]));
}

class _AppointmentPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider), boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
    ),
    child: Column(children: [
      const Icon(Icons.calendar_today_outlined, color: AppColors.textHint, size: 40),
      const SizedBox(height: 12),
      const Text('Aucun rendez-vous prévu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      const Text('Vos prochains rendez-vous apparaîtront ici', style: TextStyle(fontSize: 12, color: AppColors.textHint), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Prendre un rendez-vous'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
      ),
    ]),
  );
}
