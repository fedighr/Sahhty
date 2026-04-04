import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../data/models/doctor_model.dart';
import '../../../data/services/doctor_service.dart';

final doctorsProvider = FutureProvider<List<Doctor>>((ref) async {
  return ref.read(doctorServiceProvider).getDoctors();
});

class DoctorsListScreen extends ConsumerWidget {
  const DoctorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Médecins disponibles', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: doctorsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(itemCount: 5),
        ),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (doctors) {
          if (doctors.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.medical_services_outlined,
              title: 'Aucun médecin disponible',
              subtitle: 'La liste des médecins apparaîtra ici.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: doctors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final doctor = doctors[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.fullName.isEmpty ? 'Médecin' : doctor.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doctor.specialityName ?? 'Spécialité non renseignée',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(icon: Icons.location_on_outlined, label: doctor.ville.isEmpty ? 'Ville non renseignée' : doctor.ville),
                              _InfoChip(icon: Icons.workspace_premium_outlined, label: '${doctor.experience} ans exp.'),
                              if (doctor.consultationPrice != null)
                                _InfoChip(icon: Icons.payments_outlined, label: '${doctor.consultationPrice!.toStringAsFixed(0)} TND'),
                            ],
                          ),
                          if ((doctor.bio ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              doctor.bio!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: doctor.isAvailable ? AppColors.successLight : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        doctor.isAvailable ? 'Disponible' : 'Indisponible',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: doctor.isAvailable ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
