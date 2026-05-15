import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

// ── Provider: doctors with access ─────────────────────────────────────────────
final _patientDoctorsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, patientId) async {
    final res =
        await ref.read(medicalFileServiceProvider).getPatientDoctors(patientId);
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['doctors'] ?? []);
    }
    throw res['message'] ?? 'Erreur chargement';
  },
);

class PatientDoctorAccessScreen extends ConsumerStatefulWidget {
  const PatientDoctorAccessScreen({super.key});

  @override
  ConsumerState<PatientDoctorAccessScreen> createState() =>
      _PatientDoctorAccessScreenState();
}

class _PatientDoctorAccessScreenState
    extends ConsumerState<PatientDoctorAccessScreen> {
  final _doctorIdCtrl = TextEditingController();
  bool _accepting = false;

  int? get _patientId =>
      int.tryParse(ref.read(authProvider).patientId ?? '');

  @override
  void dispose() {
    _doctorIdCtrl.dispose();
    super.dispose();
  }

  // ── Accept doctor access ───────────────────────────────────────────────────
  Future<void> _acceptAccess() async {
    final doctorId = int.tryParse(_doctorIdCtrl.text.trim());
    if (doctorId == null) {
      _snack('Veuillez entrer un ID médecin valide', isError: true);
      return;
    }
    final patientId = _patientId;
    if (patientId == null) {
      _snack('ID patiente introuvable', isError: true);
      return;
    }

    setState(() => _accepting = true);
    try {
      final res = await ref.read(medicalFileServiceProvider).acceptDoctorAccess(
            patientId: patientId,
            doctorId: doctorId,
          );
      if (!mounted) return;
      setState(() => _accepting = false);

      if (res['success'] == true) {
        _snack('Accès accordé au médecin ✓');
        _doctorIdCtrl.clear();
        if (_patientId != null) {
          ref.invalidate(_patientDoctorsProvider(_patientId!));
        }
      } else {
        _snack(res['message'] ?? 'Erreur lors de l\'acceptation', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      _snack('Erreur inattendue: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final patientId = _patientId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Médecins autorisés',
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(30),
                    AppColors.accent.withAlpha(20)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.shield_tick,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confidentialité',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vous contrôlez qui peut voir votre dossier médical. Seuls les médecins autorisés ont accès.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // ── Accept request section ────────────────────────────────
            _SectionTitle(
              icon: Iconsax.tick_circle,
              label: 'Accepter une demande d\'accès',
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Un médecin vous a envoyé une demande d\'accès ? Entrez son ID pour lui accorder l\'accès à votre dossier médical.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _doctorIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ID Médecin',
                      hintText: 'Ex: 3',
                      prefixIcon: const Icon(Iconsax.user_octagon,
                          color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _accepting ? null : _acceptAccess,
                      icon: _accepting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Iconsax.tick_circle,
                              size: 18, color: Colors.white),
                      label: Text(
                        _accepting
                            ? 'Traitement...'
                            : 'Autoriser l\'accès',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // ── Authorized doctors list ───────────────────────────────
            _SectionTitle(
              icon: Iconsax.people,
              label: 'Médecins ayant accès',
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 12),

            if (patientId == null)
              const Center(
                  child: Text('ID patiente introuvable',
                      style:
                          TextStyle(color: AppColors.textSecondary)))
            else
              Consumer(
                builder: (ctx, r, _) {
                  final doctorsAsync =
                      r.watch(_patientDoctorsProvider(patientId));
                  return doctorsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (e, _) => _EmptyState(
                      icon: Iconsax.warning_2,
                      message: 'Erreur: $e',
                    ),
                    data: (doctors) {
                      if (doctors.isEmpty) {
                        return const _EmptyState(
                          icon: Iconsax.user_octagon,
                          message:
                              'Aucun médecin n\'a accès à votre dossier pour le moment',
                        );
                      }
                      return Column(
                        children: doctors
                            .asMap()
                            .entries
                            .map(
                              (e) => _DoctorAccessCard(doctor: e.value)
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(
                                        milliseconds:
                                            300 + e.key * 60),
                                    duration: 300.ms,
                                  ),
                            )
                            .toList(),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Doctor access card ───────────────────────────────────────────────────────
class _DoctorAccessCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorAccessCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final user = doctor['user'] as Map<String, dynamic>? ?? {};
    final name =
        'Dr. ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final specialityRaw = doctor['speciality'];
    final speciality = specialityRaw is Map
        ? (specialityRaw['name'] ?? specialityRaw['title'] ?? '').toString()
        : (specialityRaw?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(25),
          child: Text(
            name.length > 4 ? name[4].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        subtitle: speciality.isNotEmpty
            ? Text(
                speciality,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              )
            : null,
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.shield_tick,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Autorisé',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
