import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/services/patient_service.dart';
import '../../../data/services/token_storage_service.dart';
import '../../../core/widgets/loading_shimmer.dart';

final patientProfileProvider = FutureProvider<Patient>((ref) async {
  final tokenStorage = ref.read(tokenStorageServiceProvider);
  final patientId = await tokenStorage.getPatientId() ?? await tokenStorage.getUserId();
  if (patientId == null) throw Exception('Utilisateur non identifié');
  return ref.read(patientServiceProvider).getProfile(patientId);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: profileAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer(itemCount: 4)),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (patient) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFFDF2F8)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('👩', style: TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 16),
                    const Text('Mes informations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(
                      'Gardez vos données à jour pour un suivi plus précis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ProfileSection(
                title: 'Repères généraux',
                icon: Icons.favorite_outline_rounded,
                children: [
                  _ProfileRow(label: 'Taille', value: '${patient.height} cm'),
                  _ProfileRow(label: 'Poids', value: '${patient.weight.toStringAsFixed(1)} kg'),
                  _ProfileRow(label: 'IMC', value: '${patient.bmi.toStringAsFixed(1)} • ${patient.bmiCategory}'),
                  _ProfileRow(label: 'Groupe sanguin', value: patient.bloodType ?? 'Non renseigné'),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: 'Santé',
                icon: Icons.medical_information_outlined,
                color: const Color(0xFF8B5CF6),
                children: [
                  _ProfileRow(label: 'Maladies chroniques', value: _safe(patient.chronicDiseases, 'Aucune')),
                  _ProfileRow(label: 'Allergies', value: _safe(patient.allergies, 'Aucune')),
                  _ProfileRow(label: 'Traitements actuels', value: _safe(patient.currentMedications, 'Aucun')),
                  _ProfileRow(label: 'Médecin traitant', value: _safe(patient.familyDoctorName, 'Non renseigné')),
                ],
              ),
              if (patient.menstrualCycle != null) ...[
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Cycle menstruel',
                  icon: Icons.calendar_today_outlined,
                  color: const Color(0xFFEC4899),
                  children: [
                    _ProfileRow(label: 'Statut', value: _menstrualStatusLabel(patient.menstrualCycle!.menstrualStatus)),
                    if (patient.menstrualCycle!.startDate != null)
                      _ProfileRow(label: 'Début', value: patient.menstrualCycle!.startDate!),
                    if (patient.menstrualCycle!.endDate != null)
                      _ProfileRow(label: 'Fin', value: patient.menstrualCycle!.endDate!),
                  ],
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _safe(String? value, String fallback) => (value == null || value.trim().isEmpty) ? fallback : value;

  String _menstrualStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Actif';
      case 'MENOPAUSE':
        return 'Ménopause';
      case 'PREPUBESCENT':
        return 'Prépubère';
      default:
        return status;
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

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
