import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../data/services/pregnancy_service.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state_widget.dart';

final pregnancyProvider = FutureProvider<Pregnancy?>((ref) async {
  return ref.read(pregnancyServiceProvider).getActivePregnancy();
});

class PregnancyDetailScreen extends ConsumerWidget {
  const PregnancyDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyAsync = ref.watch(pregnancyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ma Grossesse', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: pregnancyAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (pregnancy) {
          if (pregnancy == null || !pregnancy.isActive) {
            return const EmptyStateWidget(
              icon: Icons.pregnant_woman_rounded,
              title: 'Aucune grossesse active',
              subtitle: 'Les informations de votre grossesse apparaîtront ici.',
            );
          }

          final week = pregnancy.currentWeek ?? 0;
          final days = pregnancy.daysRemaining ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8BBD0), Color(0xFFFFCDD2), Color(0xFFFFEBEE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(pregnancy.babySize.split(' ').first, style: const TextStyle(fontSize: 60)),
                      const SizedBox(height: 12),
                      Text('Semaine $week', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF880E4F))),
                      const SizedBox(height: 4),
                      Text(pregnancy.babySize.split(' ').skip(1).join(' '), style: const TextStyle(fontSize: 14, color: Color(0xFFAD1457))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatPill(label: '$days', subtitle: 'jours restants'),
                          const SizedBox(width: 12),
                          _StatPill(label: '${pregnancy.trimester}', subtitle: 'trimestre'),
                          const SizedBox(width: 12),
                          _StatPill(label: '${(week * 7) % 7 + (DateTime.now().difference(DateTime.tryParse(pregnancy.startDate!) ?? DateTime.now()).inDays % 7)}', subtitle: 'jours'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Détails
                _DetailCard(
                  title: 'Informations de grossesse',
                  icon: Icons.info_outline_rounded,
                  children: [
                    _DetailRow(label: 'Date du test', value: pregnancy.testDate),
                    _DetailRow(label: 'Résultat', value: pregnancy.testResult ? '✅ Positif' : '❌ Négatif'),
                    if (pregnancy.startDate != null)
                      _DetailRow(label: 'Date de début', value: _formatDate(pregnancy.startDate!)),
                    if (pregnancy.dueDate != null)
                      _DetailRow(label: 'Date prévue', value: _formatDate(pregnancy.dueDate!)),
                  ],
                ),
                const SizedBox(height: 16),

                // Développement du bébé
                _DetailCard(
                  title: 'Développement cette semaine',
                  icon: Icons.child_care_rounded,
                  color: const Color(0xFFEC407A),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _weekDescription(week),
                        style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Conseils
                _DetailCard(
                  title: 'Conseils de la semaine',
                  icon: Icons.lightbulb_outline_rounded,
                  color: AppColors.warning,
                  children: [
                    ..._weekTips(week).map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡 ', style: TextStyle(fontSize: 14)),
                              Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4))),
                            ],
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String _weekDescription(int week) {
    if (week <= 4) return 'L\'embryon s\'implante dans l\'utérus. Les premières cellules se divisent rapidement pour former les futures structures du bébé.';
    if (week <= 8) return 'Le cœur du bébé bat déjà ! Les bras et les jambes commencent à se former. Le système nerveux se développe rapidement.';
    if (week <= 12) return 'Tous les organes vitaux sont en place. Le bébé commence à bouger, même si vous ne le sentez pas encore. Les doigts et les orteils se forment.';
    if (week <= 16) return 'Le bébé grandit rapidement. Les traits du visage se précisent. Il peut faire des grimaces et sucer son pouce.';
    if (week <= 20) return 'Le bébé est très actif ! Vous pouvez commencer à sentir ses mouvements. C\'est le moment de l\'échographie morphologique.';
    if (week <= 24) return 'Le bébé entend les sons. Il réagit à votre voix et à la musique. Ses poumons continuent de se développer.';
    if (week <= 28) return 'Le bébé ouvre et ferme les yeux. Il prend du poids rapidement. Le cerveau se développe à grande vitesse.';
    if (week <= 32) return 'Le bébé se prépare pour la naissance. Il se positionne progressivement tête en bas. Ses poumons arrivent à maturité.';
    if (week <= 36) return 'Le bébé est presque prêt ! Il accumule de la graisse sous la peau. Ses mouvements peuvent être moins fréquents car il a moins de place.';
    return 'Le bébé est à terme ! Il peut naître à tout moment. Surveillez les signes de travail et restez en contact avec votre médecin.';
  }

  List<String> _weekTips(int week) {
    if (week <= 12) {
      return [
        'Prenez de l\'acide folique quotidiennement.',
        'Évitez l\'alcool et le tabac.',
        'Mangez équilibré et hydratez-vous bien.',
      ];
    }
    if (week <= 24) {
      return [
        'Continuez les suppléments de fer et acide folique.',
        'Faites de l\'exercice modéré (marche, natation).',
        'Surveillez votre tension artérielle régulièrement.',
      ];
    }
    return [
      'Préparez votre valise de maternité.',
      'Reposez-vous suffisamment.',
      'Surveillez les contractions et les mouvements du bébé.',
      'Consultez immédiatement en cas de saignement ou douleur intense.',
    ];
  }
}

class _StatPill extends StatelessWidget {
  final String label, subtitle;
  const _StatPill({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF880E4F))),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFFAD1457))),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.icon, this.color = AppColors.primary, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
