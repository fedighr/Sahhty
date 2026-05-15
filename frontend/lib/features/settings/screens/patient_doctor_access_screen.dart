import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

// ── Provider: pending access requests ─────────────────────────────────────────
final _pendingRequestsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, patientId) async {
    final res =
        await ref.read(medicalFileServiceProvider).getPatientDoctorsRequests(patientId);
    if (res['success'] == true) {
      final rawList = res['doctors'];
      if (rawList == null) return [];
      return (rawList as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    throw res['message'] ?? 'Erreur chargement';
  },
);

// ── Provider: doctors with access ─────────────────────────────────────────────
final _patientDoctorsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, patientId) async {
    final res =
        await ref.read(medicalFileServiceProvider).getPatientDoctors(patientId);
    if (res['success'] == true) {
      final rawList = res['doctors'];
      if (rawList == null) return [];
      return (rawList as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
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
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedDoctor;
  bool _searching = false;
  bool _accepting = false;

  String? _searchError;

  int? get _patientId =>
      int.tryParse(ref.read(authProvider).patientId ?? '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final patientId = _patientId;
      if (patientId != null) {
        ref.invalidate(_pendingRequestsProvider(patientId));
        ref.invalidate(_patientDoctorsProvider(patientId));
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search doctors by name ─────────────────────────────────────────────────
  Future<void> _searchDoctors(String query) async {
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _selectedDoctor = null; _searchError = null; });
      return;
    }
    setState(() { _searching = true; _searchError = null; });
    try {
      final res = await ref.read(medicalFileServiceProvider).searchDoctors(query.trim());
      if (!mounted) return;
      if (res['success'] == false) {
        setState(() { _searchResults = []; _searching = false; _searchError = res['message']?.toString() ?? 'Erreur de recherche'; });
        return;
      }
      final results = res['results'] as List? ?? [];
      if (results.isEmpty) {
        setState(() { _searchResults = []; _searching = false; _searchError = 'Aucun médecin trouvé pour "${query.trim()}"'; });
        return;
      }
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(results);
        _searching = false;
        _searchError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _searching = false; _searchError = 'Erreur: $e'; });
    }
  }

  // ── Accept doctor access ───────────────────────────────────────────────────
  Future<void> _acceptAccess() async {
    final doctor = _selectedDoctor;
    if (doctor == null) {
      _snack('Veuillez sélectionner un médecin', isError: true);
      return;
    }
    final doctorId = int.tryParse(doctor['id']?.toString() ?? '');
    if (doctorId == null) {
      _snack('ID médecin invalide', isError: true);
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
        _searchCtrl.clear();
        setState(() { _searchResults = []; _selectedDoctor = null; });
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

  // ── Accept pending request ─────────────────────────────────────────────────
  Future<void> _acceptRequest(int doctorId, String doctorName) async {
    final patientId = _patientId;
    if (patientId == null) return;
    final res = await ref.read(medicalFileServiceProvider).acceptDoctorAccess(
          patientId: patientId,
          doctorId: doctorId,
        );
    if (!mounted) return;
    if (res['success'] == true) {
      _snack('Accès accordé à $doctorName ✓');
      ref.invalidate(_pendingRequestsProvider(patientId));
      ref.invalidate(_patientDoctorsProvider(patientId));
    } else {
      _snack(res['message'] ?? "Erreur lors de l'acceptation", isError: true);
    }
  }

  // ── Reject pending request ─────────────────────────────────────────────────
  Future<void> _rejectRequest(int doctorId, String doctorName) async {
    final patientId = _patientId;
    if (patientId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Refuser la demande', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Voulez-vous refuser la demande d'accès de $doctorName ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ref.read(medicalFileServiceProvider).revokeAccess(
          patientId: patientId,
          doctorId: doctorId,
        );
    if (!mounted) return;
    if (res['success'] == true) {
      _snack('Demande refusée');
      ref.invalidate(_pendingRequestsProvider(patientId));
    } else {
      _snack(res['message'] ?? 'Erreur lors du refus', isError: true);
    }
  }

  // ── Revoke doctor access ───────────────────────────────────────────────────
  Future<void> _revokeAccess(int doctorId, String doctorName) async {
    final patientId = _patientId;
    if (patientId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Révoquer l\'accès',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Êtes-vous sûre de vouloir révoquer l\'accès de $doctorName à votre dossier médical ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Révoquer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ref.read(medicalFileServiceProvider).revokeAccess(
          patientId: patientId,
          doctorId: doctorId,
        );
    if (!mounted) return;
    if (res['success'] == true) {
      _snack('Accès révoqué avec succès');
      ref.invalidate(_patientDoctorsProvider(patientId));
    } else {
      _snack(res['message'] ?? 'Erreur lors de la révocation', isError: true);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'Un médecin vous a envoyé une demande d\'accès ? Recherchez-le par nom pour lui accorder l\'accès à votre dossier médical.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // ── Search field ──────────────────────────────────
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _searchDoctors,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un médecin',
                      hintText: 'Tapez le nom du médecin...',
                      prefixIcon: const Icon(Iconsax.search_normal,
                          color: AppColors.primary, size: 20),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary)),
                            )
                          : _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Iconsax.close_circle,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _selectedDoctor = null;
                                      _searchError = null;
                                    });
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                  // ── Search results ────────────────────────────────
                  if (_searchError != null && _searchResults.isEmpty && _selectedDoctor == null && !_searching) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.info_circle, color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_searchError!, style: TextStyle(color: Colors.orange.shade800, fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                  if (_searchResults.isNotEmpty && _selectedDoctor == null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _searchResults.take(5).map((d) {
                          final rawUser = d['user'];
                          final user = (rawUser is Map) ? Map<String, dynamic>.from(rawUser) : <String, dynamic>{};
                          final name = 'Dr. ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                          final specialityRaw = d['speciality'];
                          final spec = specialityRaw is Map
                              ? (specialityRaw['name'] ?? '').toString()
                              : (specialityRaw?.toString() ?? '');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withAlpha(25),
                              child: Text(
                                name.length > 4 ? name[4].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: spec.isNotEmpty
                                ? Text(spec,
                                    style: const TextStyle(fontSize: 12))
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedDoctor = d;
                                _searchCtrl.text = name;
                                _searchResults = [];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  // ── Selected doctor chip ──────────────────────────
                  if (_selectedDoctor != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.tick_circle,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchCtrl.text,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedDoctor = null;
                              _searchCtrl.clear();
                            }),
                            child: const Icon(Iconsax.close_circle,
                                size: 18,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
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

            // ── Pending requests section ──────────────────────────────
            _SectionTitle(
              icon: Iconsax.clock,
              label: 'Demandes en attente',
            ).animate().fadeIn(delay: 175.ms, duration: 300.ms),
            const SizedBox(height: 12),

            if (patientId != null)
              Consumer(
                builder: (ctx, r, _) {
                  final pendingAsync = r.watch(_pendingRequestsProvider(patientId));
                  return pendingAsync.when(
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (requests) {
                      if (requests.isEmpty) {
                        return const _EmptyState(
                          icon: Iconsax.clock,
                          message: 'Aucune demande en attente',
                        );
                      }
                      return Column(
                        children: requests.asMap().entries.map((e) {
                          final d = e.value;
                          final doctorId = int.tryParse(d['id']?.toString() ?? '') ?? 0;
                          final user = d['user'] as Map<String, dynamic>? ?? {};
                          final name = 'Dr. ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                          return _PendingRequestCard(
                            doctor: d,
                            onAccept: () => _acceptRequest(doctorId, name),
                            onReject: () => _rejectRequest(doctorId, name),
                          ).animate().fadeIn(
                                delay: Duration(milliseconds: 200 + e.key * 60),
                                duration: 300.ms,
                              );
                        }).toList(),
                      );
                    },
                  );
                },
              ),

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
                    loading: () => const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator(
                            color: AppColors.primary))),
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
                              (e) {
                                final d = e.value;
                                final doctorId = int.tryParse(d['id']?.toString() ?? '') ?? 0;
                                final user = d['user'] as Map<String, dynamic>? ?? {};
                                final name = 'Dr. ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                                return _DoctorAccessCard(
                                  doctor: d,
                                  onRevoke: () => _revokeAccess(doctorId, name),
                                ).animate().fadeIn(
                                      delay: Duration(milliseconds: 300 + e.key * 60),
                                      duration: 300.ms,
                                    );
                              },
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

// ─── Pending request card ─────────────────────────────────────────────────────
class _PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _PendingRequestCard({required this.doctor, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final rawUser = doctor['user'];
    final user = (rawUser is Map) ? Map<String, dynamic>.from(rawUser) : <String, dynamic>{};
    final name = 'Dr. ${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final specialityRaw = doctor['speciality'];
    final speciality = specialityRaw is Map
        ? (specialityRaw['name'] ?? specialityRaw['title'] ?? '').toString()
        : (specialityRaw?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(80)),
        boxShadow: [
          BoxShadow(color: Colors.orange.withAlpha(20), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withAlpha(30),
                  child: Text(
                    name.length > 4 ? name[4].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      if (speciality.isNotEmpty)
                        Text(speciality, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('En attente', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Iconsax.close_circle, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withAlpha(80)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Iconsax.tick_circle, size: 16, color: Colors.white),
                    label: const Text('Accepter', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Doctor access card ───────────────────────────────────────────────────────
class _DoctorAccessCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onRevoke;
  const _DoctorAccessCard({required this.doctor, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final rawUser = doctor['user'];
    final user = (rawUser is Map) ? Map<String, dynamic>.from(rawUser) : <String, dynamic>{};
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(25),
              child: Text(
                name.length > 4 ? name[4].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (speciality.isNotEmpty)
                    Text(speciality,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRevoke,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.close_circle, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('Révoquer',
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
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
