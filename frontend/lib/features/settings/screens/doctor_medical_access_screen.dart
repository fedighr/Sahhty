import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

// ── Provider: patients with access ──────────────────────────────────────────
final _doctorPatientsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, doctorId) async {
    final res =
        await ref.read(medicalFileServiceProvider).getDoctorPatients(doctorId);
    if (res['success'] == true) {
      return List<Map<String, dynamic>>.from(res['patients'] ?? []);
    }
    throw res['message'] ?? 'Erreur chargement';
  },
);

class DoctorMedicalAccessScreen extends ConsumerStatefulWidget {
  const DoctorMedicalAccessScreen({super.key});

  @override
  ConsumerState<DoctorMedicalAccessScreen> createState() =>
      _DoctorMedicalAccessScreenState();
}

class _DoctorMedicalAccessScreenState
    extends ConsumerState<DoctorMedicalAccessScreen> {
  final _patientIdCtrl = TextEditingController();
  bool _requesting = false;

  int? get _doctorId =>
      int.tryParse(ref.read(authProvider).doctorId ?? '');

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    super.dispose();
  }

  // ── Request access ─────────────────────────────────────────────────────────
  Future<void> _requestAccess() async {
    final patientId = int.tryParse(_patientIdCtrl.text.trim());
    if (patientId == null) {
      _snack('Veuillez entrer un ID patient valide', isError: true);
      return;
    }
    final doctorId = _doctorId;
    if (doctorId == null) {
      _snack('ID médecin introuvable', isError: true);
      return;
    }

    setState(() => _requesting = true);
    try {
      final res = await ref.read(medicalFileServiceProvider).requestMedicalAccess(
            patientId: patientId,
            doctorId: doctorId,
          );
      if (!mounted) return;
      setState(() => _requesting = false);

      if (res['success'] == true) {
        _snack('Demande d\'accès envoyée. La patiente sera notifiée pour valider.');
        _patientIdCtrl.clear();
        if (_doctorId != null) ref.invalidate(_doctorPatientsProvider(_doctorId!));
      } else {
        _snack(res['message'] ?? 'Erreur lors de la demande', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _requesting = false);
      _snack('Erreur inattendue: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? DoctorColors.error : DoctorColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── View patient files ─────────────────────────────────────────────────────
  void _viewPatientFiles(Map<String, dynamic> patient) {
    final patientId =
        int.tryParse(patient['id']?.toString() ?? '');
    if (patientId == null) {
      _snack('ID patient invalide', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PatientFilesReadOnlyScreen(
          patientId: patientId,
          patientName:
              '${patient['user']?['first_name'] ?? ''} ${patient['user']?['last_name'] ?? ''}'
                  .trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = _doctorId;

    return Scaffold(
      backgroundColor: DoctorColors.background,
      appBar: AppBar(
        backgroundColor: DoctorColors.primary,
        title: const Text(
          'Accès aux dossiers médicaux',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Request access card ──────────────────────────────────
            _SectionTitle(
              icon: Iconsax.document_like,
              label: 'Demander accès à un dossier',
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: DoctorColors.primary.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entrez l\'ID de la patiente pour demander accès à son dossier médical. Elle recevra une notification pour accepter.',
                    style: TextStyle(
                        color: DoctorColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _patientIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ID Patiente',
                      hintText: 'Ex: 11',
                      prefixIcon: const Icon(Iconsax.user,
                          color: DoctorColors.primary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: DoctorColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: DoctorColors.background,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _requesting ? null : _requestAccess,
                      icon: _requesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Iconsax.send_1,
                              size: 18, color: Colors.white),
                      label: Text(
                        _requesting
                            ? 'Envoi en cours...'
                            : 'Envoyer la demande',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DoctorColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // ── Patients with access ─────────────────────────────────
            _SectionTitle(
              icon: Iconsax.people,
              label: 'Patientes avec accès accordé',
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 12),

            if (doctorId == null)
              const Center(
                  child: Text('ID médecin introuvable',
                      style:
                          TextStyle(color: DoctorColors.textSecondary)))
            else
              Consumer(
                builder: (ctx, r, _) {
                  final patientsAsync =
                      r.watch(_doctorPatientsProvider(doctorId));
                  return patientsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: DoctorColors.primary)),
                    error: (e, _) => _EmptyState(
                      icon: Iconsax.warning_2,
                      message: 'Erreur: $e',
                    ),
                    data: (patients) {
                      if (patients.isEmpty) {
                        return const _EmptyState(
                          icon: Iconsax.document_text,
                          message:
                              'Aucune patiente ne vous a encore accordé l\'accès',
                        );
                      }
                      return Column(
                        children: patients
                            .asMap()
                            .entries
                            .map(
                              (e) => _PatientAccessCard(
                                patient: e.value,
                                onViewFiles: () =>
                                    _viewPatientFiles(e.value),
                              ).animate().fadeIn(
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

// ─── Patient access card ──────────────────────────────────────────────────────
class _PatientAccessCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onViewFiles;

  const _PatientAccessCard({
    required this.patient,
    required this.onViewFiles,
  });

  @override
  Widget build(BuildContext context) {
    final user = patient['user'] as Map<String, dynamic>? ?? {};
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final email = user['email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: DoctorColors.primary.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: DoctorColors.primary.withAlpha(25),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: DoctorColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name.isEmpty ? 'Patiente' : name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: DoctorColors.textPrimary),
        ),
        subtitle: Text(
          email,
          style: const TextStyle(
              color: DoctorColors.textSecondary, fontSize: 12),
        ),
        trailing: ElevatedButton.icon(
          onPressed: onViewFiles,
          icon: const Icon(Iconsax.document_text, size: 16, color: Colors.white),
          label:
              const Text('Voir', style: TextStyle(color: Colors.white, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: DoctorColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ─── Read-only patient files screen ──────────────────────────────────────────
class _PatientFilesReadOnlyScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const _PatientFilesReadOnlyScreen({
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<_PatientFilesReadOnlyScreen> createState() =>
      _PatientFilesReadOnlyScreenState();
}

class _PatientFilesReadOnlyScreenState
    extends ConsumerState<_PatientFilesReadOnlyScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() { _loading = true; _error = null; });
    final res = await ref
        .read(medicalFileServiceProvider)
        .getPatientMedicalFiles(widget.patientId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _files = List<Map<String, dynamic>>.from(res['medical_files'] ?? []);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Erreur chargement';
        _loading = false;
      });
    }
  }

  static const _typeLabels = {
    'REPORT': 'Compte rendu',
    'ULTRASOUND': 'Échographie',
    'BLOOD_TEST': 'Analyse de sang',
    'URINE_TEST': 'Analyse d\'urine',
    'PRESCRIPTION': 'Ordonnance',
    'VACCINATION': 'Vaccination',
    'ECHO': 'Échocardiographie',
    'OTHER': 'Autre',
  };

  static const _typeColors = {
    'REPORT': Color(0xFF6C63FF),
    'ULTRASOUND': Color(0xFF00BFA5),
    'BLOOD_TEST': Color(0xFFE53935),
    'URINE_TEST': Color(0xFFFF8F00),
    'PRESCRIPTION': Color(0xFF1E88E5),
    'VACCINATION': Color(0xFF43A047),
    'ECHO': Color(0xFFE91E63),
    'OTHER': Color(0xFF757575),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DoctorColors.background,
      appBar: AppBar(
        backgroundColor: DoctorColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dossier médical',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(widget.patientName,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DoctorColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.warning_2,
                          color: DoctorColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: DoctorColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFiles,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: DoctorColors.primary),
                        child: const Text('Réessayer',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _files.isEmpty
                  ? const _EmptyState(
                      icon: Iconsax.document_text,
                      message: 'Aucun fichier médical dans ce dossier',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFiles,
                      color: DoctorColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _files.length,
                        itemBuilder: (ctx, i) {
                          final file = _files[i];
                          final type = file['type'] as String? ?? 'OTHER';
                          final label = _typeLabels[type] ?? 'Autre';
                          final color = _typeColors[type] ?? const Color(0xFF757575);
                          final dateStr = _formatDate(file['upload_date']);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: color.withAlpha(30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Iconsax.document_text,
                                    color: color, size: 22),
                              ),
                              title: Text(label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: DoctorColors.textPrimary)),
                              subtitle: Text(dateStr,
                                  style: const TextStyle(
                                      color: DoctorColors.textSecondary,
                                      fontSize: 12)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '📄 Fichier',
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                                delay: Duration(milliseconds: i * 50),
                                duration: 300.ms);
                        },
                      ),
                    ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      return DateFormat('dd/MM/yyyy', 'fr').format(DateTime.parse(date.toString()));
    } catch (_) {
      return date.toString();
    }
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
            color: DoctorColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DoctorColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: DoctorColors.textPrimary,
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
                color: DoctorColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
