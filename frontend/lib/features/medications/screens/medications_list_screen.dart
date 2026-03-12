import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/services/medication_service.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state_widget.dart';

final treatmentsProvider = FutureProvider<List<Treatment>>((ref) async {
  return ref.read(medicationServiceProvider).getTreatments();
});

class MedicationsListScreen extends ConsumerWidget {
  const MedicationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(treatmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Médicaments', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: treatmentsAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (treatments) {
          if (treatments.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.medication_outlined,
              title: 'Aucun traitement',
              subtitle: 'Vos traitements et ordonnances apparaîtront ici.',
            );
          }

          final active = treatments.where((t) => t.isActive).toList();
          final inactive = treatments.where((t) => !t.isActive).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (active.isNotEmpty) ...[
                const Text('Traitements en cours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...active.map((t) => _TreatmentCard(treatment: t)),
              ],
              if (inactive.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Traitements terminés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ...inactive.map((t) => _TreatmentCard(treatment: t, isInactive: true)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final Treatment treatment;
  final bool isInactive;
  const _TreatmentCard({required this.treatment, this.isInactive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInactive ? AppColors.surface.withOpacity(0.6) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: isInactive ? AppColors.textHint.withOpacity(0.1) : const Color(0xFF7C4DFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.medication_rounded,
              color: isInactive ? AppColors.textHint : const Color(0xFF7C4DFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treatment.medication?.name ?? 'Médicament',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isInactive ? AppColors.textSecondary : AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_pharmacy_outlined, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(treatment.dose, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(treatment.frequency, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                if (treatment.medication?.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      treatment.medication!.description!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (treatment.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Actif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
        ],
      ),
    );
  }
}
