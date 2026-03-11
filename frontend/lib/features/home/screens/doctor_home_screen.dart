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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DoctorWelcomeBanner()
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 28),
                _sectionTitle('Statistiques', Icons.bar_chart_rounded),
                const SizedBox(height: 14),
                _StatsRow().animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 28),
                _sectionTitle('Accès rapide', Icons.flash_on_rounded),
                const SizedBox(height: 14),
                _DoctorQuickActions().animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 28),
                _sectionTitle('Consultations du jour', Icons.today_rounded),
                const SizedBox(height: 14),
                _ConsultationPlaceholder().animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 28),
                _sectionTitle('Patients récents', Icons.people_alt_rounded),
                const SizedBox(height: 14),
                _RecentPatientsCard().animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t, IconData icon) => Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00ACC1)),
          const SizedBox(width: 8),
          Text(
            t,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) =>
      SliverAppBar(
        expandedHeight: 140,
        floating: true,
        pinned: true,
        backgroundColor: const Color(0xFF006064),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00ACC1), Color(0xFF006064)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_outlined,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🩺 Espace Médecin',
                          style:
                              TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tableau de bord',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _AppBarIconButton(
                      icon: Icons.notifications_outlined,
                      onTap: () {},
                      badge: true,
                    ),
                    const SizedBox(width: 8),
                    _AppBarIconButton(
                      icon: Icons.logout_rounded,
                      onTap: () async {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .signOut();
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (badge)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _DoctorWelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00ACC1), Color(0xFF006064)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue, Docteur 👨‍⚕️',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vous avez 0 consultation\nprévue aujourd\'hui.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle,
                                color: Colors.white, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'Disponible',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Modifier →',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('🏥', style: TextStyle(fontSize: 52)),
          ],
        ),
      );
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: const [
          _StatCard(
              label: 'Patients',
              value: '--',
              icon: Icons.people_outline_rounded,
              color: AppColors.primary),
          SizedBox(width: 12),
          _StatCard(
              label: 'Rendez-vous',
              value: '--',
              icon: Icons.event_note_outlined,
              color: Color(0xFF00ACC1)),
          SizedBox(width: 12),
          _StatCard(
              label: 'Dossiers',
              value: '--',
              icon: Icons.folder_shared_outlined,
              color: Color(0xFF7C4DFF)),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      );
}

class _DoctorQuickActions extends StatelessWidget {
  static const _actions = [
    (Icons.person_search_outlined, 'Mes\npatients', AppColors.primary),
    (Icons.add_box_outlined, 'Nouvelle\nconsult', Color(0xFF00ACC1)),
    (Icons.folder_shared_outlined, 'Dossiers', Color(0xFF7C4DFF)),
    (Icons.event_available_outlined, 'Planning', Color(0xFF4CAF50)),
  ];

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _actions
            .map((a) => _ActionTile(icon: a.$1, label: a.$2, color: a.$3))
            .toList(),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionTile(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {},
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: color.withOpacity(0.15), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _ConsultationPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 12)
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00ACC1).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_outlined,
                  color: Color(0xFF00ACC1), size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aucune consultation aujourd\'hui',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vos consultations du jour\napparaîtront ici.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textHint, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Ajouter une consultation',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ACC1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
}

class _RecentPatientsCard extends StatelessWidget {
  static const _patients = [
    ('Sara B.', 'Suivi grossesse', '09:00', Color(0xFFE91E63)),
    ('Amina K.', 'Tension artérielle', '10:30', Color(0xFF00ACC1)),
    ('Fatima L.', 'Diabète type 2', '14:00', Color(0xFF7C4DFF)),
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prochains patients',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00ACC1),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._patients.map((p) => _PatientItem(
                  name: p.$1,
                  reason: p.$2,
                  time: p.$3,
                  color: p.$4,
                )),
          ],
        ),
      );
}

class _PatientItem extends StatelessWidget {
  final String name, reason, time;
  final Color color;

  const _PatientItem({
    required this.name,
    required this.reason,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                name[0],
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                time,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}
