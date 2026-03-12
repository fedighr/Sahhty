import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/services/patient_service.dart';
import '../../../core/widgets/loading_shimmer.dart';

final patientProfileProvider = FutureProvider<Patient>((ref) async {
  return ref.read(patientServiceProvider).getProfile();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: profileAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (patient) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('👩', style: TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 24),

              // Infos générales
              _ProfileSection(
                title: 'Informations générales',
                icon: Icons.person_outline_rounded,
                children: [
                  _ProfileRow(label: 'Taille', value: '${patient.height} cm'),
                  _ProfileRow(label: 'Poids', value: '${patient.weight} kg'),
                  _ProfileRow(label: 'IMC', value: '${patient.bmi.toStringAsFixed(1)} (${patient.bmiCategory})'),
                  _ProfileRow(label: 'Groupe sanguin', value: patient.bloodType ?? 'Non renseigné'),
                ],
              ),
              const SizedBox(height: 16),

              // Santé
              _ProfileSection(
                title: 'Santé',
                icon: Icons.medical_information_outlined,
                children: [
                  _ProfileRow(label: 'Maladies chroniques', value: patient.chronicDiseases ?? 'Aucune'),
                  _ProfileRow(label: 'Allergies', value: patient.allergies ?? 'Aucune'),
                  _ProfileRow(label: 'Médicaments actuels', value: patient.currentMedications ?? 'Aucun'),
                  _ProfileRow(label: 'Médecin traitant', value: patient.familyDoctorName ?? 'Non renseigné'),
                ],
              ),
              const SizedBox(height: 16),

              // Cycle menstruel
              if (patient.menstrualCycle != null)
                _ProfileSection(
                  title: 'Cycle menstruel',
                  icon: Icons.calendar_today_outlined,
                  color: const Color(0xFFEC407A),
                  children: [
                    _ProfileRow(label: 'Statut', value: _menstrualStatusLabel(patient.menstrualCycle!.menstrualStatus)),
                    if (patient.menstrualCycle!.startDate != null)
                      _ProfileRow(label: 'Début', value: patient.menstrualCycle!.startDate!),
                    if (patient.menstrualCycle!.endDate != null)
                      _ProfileRow(label: 'Fin', value: patient.menstrualCycle!.endDate!),
                  ],
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _menstrualStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE': return 'Actif';
      case 'MENOPAUSE': return 'Ménopause';
      case 'PREPUBESCENT': return 'Prépubère';
      default: return status;
    }
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.icon, this.color = AppColors.primary, required this.children});

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
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
