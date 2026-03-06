// lib/features/profile_setup/screens/profile_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';

class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 40),
                ).animate().scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 28),
                Text('Bienvenue sur Sahhty!',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text('Pour personnaliser votre expérience,\ncomplétez votre profil de santé.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 48),
                _ProfileCard(
                  icon: Icons.personal_injury_outlined,
                  title: 'Je suis Patient',
                  subtitle: 'Suivre ma santé, mes rendez-vous\net mes résultats médicaux',
                  gradient: AppColors.primaryGradient,
                  onTap: () => context.push(AppRoutes.patientSetup, extra: ''),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                _ProfileCard(
                  icon: Icons.local_hospital_outlined,
                  title: 'Je suis Médecin',
                  subtitle: 'Gérer mes patients, consultations\net dossiers médicaux',
                  gradient: const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF006064)]),
                  onTap: () => context.push(AppRoutes.doctorSetup, extra: ''),
                ).animate().fadeIn(delay: 620.ms).slideY(begin: 0.2, end: 0),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.patientHome),
                  child: const Text('Compléter plus tard →',
                      style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4)),
          ])),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ),
        ]),
      ),
    );
  }
}
