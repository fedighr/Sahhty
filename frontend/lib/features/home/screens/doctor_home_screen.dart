// lib/features/home/screens/doctor_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_notifier.dart';

class DoctorHomeScreen extends ConsumerWidget {
  const DoctorHomeScreen({super.key});

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
              _StatsRow().animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 24),
              _sectionTitle('Accès rapide'),
              const SizedBox(height: 12),
              _DoctorQuickActions().animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 24),
              _sectionTitle('Consultations du jour'),
              const SizedBox(height: 12),
              _ConsultationPlaceholder().animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) => SliverAppBar(
    expandedHeight: 130, floating: true, pinned: true,
    backgroundColor: const Color(0xFF006064), elevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF006064)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.local_hospital_outlined, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('Tableau de bord', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const Text('Espace Médecin', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          ])),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            }),
        ]),
      ),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    _StatCard(label: 'Patients', value: '--', icon: Icons.people_outline_rounded, color: AppColors.primary),
    const SizedBox(width: 12),
    _StatCard(label: 'Rendez-vous', value: '--', icon: Icons.event_note_outlined, color: const Color(0xFF00ACC1)),
    const SizedBox(width: 12),
    _StatCard(label: 'Disponible', value: 'Oui', icon: Icons.check_circle_outline_rounded, color: const Color(0xFF4CAF50)),
  ]);
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
    ]),
  ));
}

class _DoctorQuickActions extends StatelessWidget {
  static const _actions = [
    (Icons.person_search_outlined,    'Mes patients',    AppColors.primary),
    (Icons.add_box_outlined,          'Nouvelle consult',Color(0xFF00ACC1)),
    (Icons.folder_shared_outlined,    'Dossiers',        Color(0xFF7C4DFF)),
    (Icons.event_available_outlined,  'Planning',        Color(0xFF4CAF50)),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 12, mainAxisSpacing: 0, childAspectRatio: 0.8,
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
    Container(width: 56, height: 56,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: color, size: 26)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary), textAlign: TextAlign.center),
  ]);
}

class _ConsultationPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.divider),
      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
    ),
    child: Column(children: [
      const Icon(Icons.event_busy_outlined, color: AppColors.textHint, size: 40),
      const SizedBox(height: 12),
      const Text('Aucune consultation aujourd\'hui', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 4),
      const Text('Vos consultations du jour apparaîtront ici', style: TextStyle(fontSize: 12, color: AppColors.textHint), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Ajouter une consultation'),
        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF00ACC1), side: const BorderSide(color: Color(0xFF00ACC1))),
      ),
    ]),
  );
}
