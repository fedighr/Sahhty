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
        title: const Text('Ma grossesse', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: pregnancyAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer(itemCount: 4)),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (pregnancy) {
          if (pregnancy == null || !pregnancy.isActive) {
            return const EmptyStateWidget(
              icon: Icons.pregnant_woman_rounded,
              title: 'Aucune grossesse active',
              subtitle: 'Les informations de votre grossesse apparaîtront ici dès qu’elles seront disponibles.',
            );
          }

          final week = pregnancy.currentWeek ?? 0;
          final days = pregnancy.daysRemaining ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFDF2F8), Color(0xFFEFF6FF)]),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      const Text('🤰', style: TextStyle(fontSize: 54)),
                      const SizedBox(height: 12),
                      Text('Semaine $week', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(pregnancy.babySize, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _StatPill(label: '$days', subtitle: 'jours restants')),
                          const SizedBox(width: 12),
                          Expanded(child: _StatPill(label: '${pregnancy.trimester}', subtitle: 'trimestre')),
                          const SizedBox(width: 12),
                          Expanded(child: _StatPill(label: _formatDateShort(pregnancy.dueDate), subtitle: 'terme')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _DetailCard(
                  title: 'Informations clés',
                  icon: Icons.info_outline_rounded,
                  children: [
                    _DetailRow(label: 'Date du test', value: _formatDate(pregnancy.testDate)),
                    _DetailRow(label: 'Résultat', value: pregnancy.testResult ? 'Positif' : 'Négatif'),
                    if (pregnancy.startDate != null) _DetailRow(label: 'Début', value: _formatDate(pregnancy.startDate!)),
                    if (pregnancy.dueDate != null) _DetailRow(label: 'Date prévue', value: _formatDate(pregnancy.dueDate!)),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Développement cette période',
                  icon: Icons.child_care_rounded,
                  color: const Color(0xFFEC4899),
                  children: [
                    Text(_weekDescription(week), style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailCard(
                  title: 'Conseils utiles',
                  icon: Icons.lightbulb_outline_rounded,
                  color: AppColors.warning,
                  children: _weekTips(week)
                      .map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.warning, fontSize: 16)),
                                Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45))),
                              ],
                            ),
                          ))
                      .toList(),
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
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(parsed);
  }

  String _formatDateShort(String? date) {
    if (date == null || date.isEmpty) return '—';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('dd/MM', 'fr_FR').format(parsed);
  }

  String _weekDescription(int week) {
    if (week <= 8) return 'Le tout début de la grossesse est une phase de mise en place rapide. Le développement est intense et le repos compte beaucoup.';
    if (week <= 12) return 'Les organes essentiels se mettent en place. Une bonne alimentation et le suivi médical précoce sont importants.';
    if (week <= 24) return 'Votre bébé grandit activement. Les mouvements peuvent commencer à se faire sentir et le suivi devient plus concret.';
    if (week <= 32) return 'Le bébé gagne du poids, ses organes mûrissent et votre confort mérite une attention particulière.';
    return 'La naissance approche. Restez attentive aux signes d’alerte et gardez vos consultations bien planifiées.';
  }

  List<String> _weekTips(int week) {
    if (week <= 12) {
      return [
        'Hydratez-vous bien et évitez l’automédication.',
        'Consultez rapidement si les nausées deviennent sévères ou en cas de saignement.',
        'Pensez à vos compléments prescrits par votre médecin.',
      ];
    }
    if (week <= 27) {
      return [
        'Surveillez votre tension et votre poids régulièrement.',
        'Maintenez une activité douce si elle est autorisée.',
        'Préparez vos examens et votre suivi de trimestre.',
      ];
    }
    return [
      'Surveillez les mouvements du bébé et consultez si vous les sentez diminuer.',
      'Préparez les affaires nécessaires pour la maternité.',
      'Consultez immédiatement en cas de contractions régulières, saignement ou perte des eaux.',
    ];
  }
}

class _StatPill extends StatelessWidget {
  final String label, subtitle;
  const _StatPill({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
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
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withValues(alpha: 0.24), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
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
