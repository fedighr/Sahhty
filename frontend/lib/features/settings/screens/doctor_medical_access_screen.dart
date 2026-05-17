import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/data/services/measurement_service.dart';
import 'package:sahhty/data/services/medication_service.dart';
import 'package:sahhty/data/services/dio_client.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

// ── No global provider needed — patients loaded in local state ──────────────

class DoctorMedicalAccessScreen extends ConsumerStatefulWidget {
  const DoctorMedicalAccessScreen({super.key});

  @override
  ConsumerState<DoctorMedicalAccessScreen> createState() =>
      _DoctorMedicalAccessScreenState();
}

class _DoctorMedicalAccessScreenState
    extends ConsumerState<DoctorMedicalAccessScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedPatient;
  bool _searching = false;
  bool _requesting = false;
  String? _searchError;

  // Local state for patients list
  List<Map<String, dynamic>> _patients = [];
  bool _patientsLoading = true;
  String? _patientsError;

  int? get _doctorId =>
      int.tryParse(ref.read(authProvider).doctorId ?? '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPatients());
  }

  Future<void> _loadPatients() async {
    final doctorId = _doctorId;
    if (doctorId == null) {
      if (mounted) setState(() { _patientsLoading = false; _patientsError = 'ID médecin introuvable'; });
      return;
    }
    if (mounted) setState(() { _patientsLoading = true; _patientsError = null; });
    try {
      final res = await ref.read(medicalFileServiceProvider).getDoctorPatients(doctorId);
      if (!mounted) return;
      if (res['success'] == true) {
        final rawList = res['patients'] as List? ?? [];
        setState(() {
          _patients = rawList.map((item) {
            if (item is Map) return Map<String, dynamic>.from(item);
            return <String, dynamic>{};
          }).where((m) => m.isNotEmpty).toList();
          _patientsLoading = false;
        });
      } else {
        setState(() {
          _patientsError = res['message']?.toString() ?? 'Erreur chargement';
          _patientsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _patientsLoading = false; _patientsError = 'Erreur: $e'; });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search patients by name ─────────────────────────────────────────────────
  Future<void> _searchPatients(String query) async {
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _selectedPatient = null; _searchError = null; });
      return;
    }
    setState(() { _searching = true; _searchError = null; });
    try {
      final res = await ref.read(medicalFileServiceProvider).searchPatients(query.trim());
      if (!mounted) return;
      if (res['success'] == false) {
        setState(() {
          _searchResults = [];
          _searching = false;
          _searchError = res['message']?.toString() ?? 'Erreur de recherche';
        });
        return;
      }
      final results = res['results'] as List? ?? [];
      if (results.isEmpty) {
        setState(() {
          _searchResults = [];
          _searching = false;
          _searchError = 'Aucune patiente trouvée pour "${query.trim()}"';
        });
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

  // ── Request access ─────────────────────────────────────────────────────────
  Future<void> _requestAccess() async {
    final patient = _selectedPatient;
    if (patient == null) {
      _snack('Veuillez sélectionner une patiente', isError: true);
      return;
    }
    final patientId = int.tryParse(patient['id']?.toString() ?? '');
    if (patientId == null) {
      _snack('ID patiente invalide', isError: true);
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
        _searchCtrl.clear();
        setState(() { _searchResults = []; _selectedPatient = null; });
        _loadPatients();
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
    final userRaw = patient['user'];
    final userMap = (userRaw is Map) ? Map<String, dynamic>.from(userRaw) : <String, dynamic>{};
    final patientName = '${userMap['first_name'] ?? ''} ${userMap['last_name'] ?? ''}'.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PatientFilesReadOnlyScreen(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

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
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh_2, color: Colors.white),
            tooltip: 'Actualiser',
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: DoctorColors.primary,
        onRefresh: () async {
          await _loadPatients();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'Recherchez la patiente par nom pour demander accès à son dossier médical. Elle recevra une notification pour accepter.',
                    style: TextStyle(
                        color: DoctorColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // ── Search field ──────────────────────────────────
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _searchPatients,
                    decoration: InputDecoration(
                      labelText: 'Rechercher une patiente',
                      hintText: 'Tapez le nom de la patiente...',
                      prefixIcon: const Icon(Iconsax.search_normal,
                          color: DoctorColors.primary, size: 20),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DoctorColors.primary)),
                            )
                              : _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Iconsax.close_circle,
                                      size: 18,
                                      color: DoctorColors.textSecondary),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _selectedPatient = null;
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
                            color: DoctorColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: DoctorColors.background,
                    ),
                  ),
                  // ── Search results ────────────────────────────────
                  if (_searchError != null && _searchResults.isEmpty && _selectedPatient == null && !_searching) ...[
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
                  if (_searchResults.isNotEmpty && _selectedPatient == null) ...[
                    const SizedBox(height: 8),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48, maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _searchResults.take(5).map((p) {
                              final userMap = p['user'];
                              final user = (userMap is Map)
                                  ? Map<String, dynamic>.from(userMap)
                                  : <String, dynamic>{};
                              final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: DoctorColors.primary.withAlpha(25),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                        color: DoctorColors.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                subtitle: Text(
                                    user['email']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 12)),
                                onTap: () {
                                  setState(() {
                                    _selectedPatient = p;
                                    _searchCtrl.text = name;
                                    _searchResults = [];
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // ── Selected patient chip ─────────────────────────
                  if (_selectedPatient != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: DoctorColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: DoctorColors.primary.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.tick_circle,
                              color: DoctorColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchCtrl.text,
                              style: const TextStyle(
                                  color: DoctorColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedPatient = null;
                              _searchCtrl.clear();
                            }),
                            child: const Icon(Iconsax.close_circle,
                                size: 18,
                                color: DoctorColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
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

            if (_patientsLoading)
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator(color: DoctorColors.primary)),
              )
            else if (_patientsError != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Iconsax.warning_2, color: DoctorColors.error, size: 36),
                        const SizedBox(height: 8),
                        const Text('Erreur de chargement', style: TextStyle(fontWeight: FontWeight.bold, color: DoctorColors.error)),
                        const SizedBox(height: 4),
                        Text(_patientsError!, style: const TextStyle(color: DoctorColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadPatients,
                    icon: const Icon(Iconsax.refresh_2, size: 16),
                    label: const Text('Réessayer'),
                    style: TextButton.styleFrom(foregroundColor: DoctorColors.primary),
                  ),
                ],
              )
            else if (_patients.isEmpty)
              const _EmptyState(
                icon: Iconsax.document_text,
                message: 'Aucune patiente ne vous a encore accordé l\'accès',
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: _patients.asMap().entries.map((e) =>
                  _PatientAccessCard(
                    patient: e.value,
                    onViewFiles: () => _viewPatientFiles(e.value),
                  ).animate().fadeIn(delay: Duration(milliseconds: 300 + e.key * 60), duration: 300.ms),
                ).toList(),
              ),
            const SizedBox(height: 24),
          ],
        ),
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
    final userRaw = patient['user'];
    final user = (userRaw is Map) ? Map<String, dynamic>.from(userRaw) : <String, dynamic>{};
    final name =
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final email = user['email']?.toString() ?? '';

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
        trailing: SizedBox(
          width: 80,
          height: 36,
          child: ElevatedButton(
            onPressed: onViewFiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Voir', style: TextStyle(color: Colors.white, fontSize: 12)),
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
    extends ConsumerState<_PatientFilesReadOnlyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Map<String, dynamic>> _files = [];
  Map<String, dynamic>? _measurements;
  List<Map<String, dynamic>> _treatments = [];

  bool _filesLoading = true;
  bool _measLoading = true;
  bool _treatLoading = true;

  String? _filesError;
  String? _measError;
  String? _treatError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAll() {
    _loadFiles();
    _loadMeasurements();
    _loadTreatments();
  }

  Future<void> _loadFiles() async {
    setState(() { _filesLoading = true; _filesError = null; });
    final res = await ref
        .read(medicalFileServiceProvider)
        .getPatientMedicalFiles(widget.patientId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _files = List<Map<String, dynamic>>.from(res['medical_files'] ?? []);
        _filesLoading = false;
      });
    } else {
      setState(() {
        _filesError = res['message'] ?? 'Erreur chargement';
        _filesLoading = false;
      });
    }
  }

  Future<void> _loadMeasurements() async {
    setState(() { _measLoading = true; _measError = null; });
    try {
      final res = await MeasurementService().getLatestMeasurements(widget.patientId);
      if (!mounted) return;
      setState(() { _measurements = res; _measLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _measError = 'Erreur: $e'; _measLoading = false; });
    }
  }

  Future<void> _loadTreatments() async {
    setState(() { _treatLoading = true; _treatError = null; });
    try {
      final res = await MedicationService().getTreatmentsByPatientId(widget.patientId);
      if (!mounted) return;
      List<Map<String, dynamic>> list = [];
      if (res is List) {
        list = List<Map<String, dynamic>>.from((res as List).map((e) => Map<String, dynamic>.from(e as Map)));
      } else if (res['treatments'] is List) {
        list = List<Map<String, dynamic>>.from((res['treatments'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      } else if (res['treatments'] is Map) {
        // Backend returns a dict: {"treatment_1": {...}, "treatment_2": {...}}
        final map = res['treatments'] as Map;
        list = map.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (res['results'] is List) {
        list = List<Map<String, dynamic>>.from((res['results'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      }
      setState(() { _treatments = list; _treatLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _treatError = 'Erreur: $e'; _treatLoading = false; });
    }
  }

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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.patientName,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh_2, color: Colors.white),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: [
            Tab(icon: const Icon(Iconsax.document_text, size: 18), text: 'Fichiers'),
            Tab(icon: const Icon(Iconsax.activity, size: 18), text: 'Mesures'),
            Tab(icon: const Icon(Iconsax.health, size: 18), text: 'Traitements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FilesTab(
            files: _files,
            loading: _filesLoading,
            error: _filesError,
            onRefresh: _loadFiles,
            context_: context,
          ),
          _MeasurementsTab(
            measurements: _measurements,
            loading: _measLoading,
            error: _measError,
            onRefresh: _loadMeasurements,
          ),
          _TreatmentsTab(
            treatments: _treatments,
            loading: _treatLoading,
            error: _treatError,
            onRefresh: _loadTreatments,
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Files ─────────────────────────────────────────────────────────────
class _FilesTab extends StatelessWidget {
  final List<Map<String, dynamic>> files;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;
  final BuildContext context_;

  const _FilesTab({
    required this.files,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.context_,
  });

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

  bool _isImage(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.webp');
  }

  Future<void> _openFile(BuildContext context, String fileUrl, String name) async {
    if (fileUrl.isEmpty) return;
    if (_isImage(fileUrl)) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _DoctorImageViewerScreen(url: fileUrl, name: name),
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Téléchargement en cours...'),
        ]),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      final tmpDir = await getTemporaryDirectory();
      final fileName = fileUrl.split('/').last.split('?').first;
      final savePath = '${tmpDir.path}/$fileName';
      final rawDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        validateStatus: (s) => s != null && s < 500,
      ));
      final token = await const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ).read(key: StorageKeys.accessToken);
      await rawDio.download(
        fileUrl,
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final result = await OpenFilex.open(savePath);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible d\'ouvrir: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      return DateFormat('dd/MM/yyyy', 'fr').format(DateTime.parse(date.toString()));
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: DoctorColors.primary));
    }
    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRefresh);
    }
    if (files.isEmpty) {
      return const _EmptyState(icon: Iconsax.document_text, message: 'Aucun fichier médical dans ce dossier');
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: DoctorColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: files.length,
        itemBuilder: (ctx, i) {
          final file = files[i];
          final type = file['type'] as String? ?? 'OTHER';
          final label = _typeLabels[type] ?? 'Autre';
          final color = _typeColors[type] ?? const Color(0xFF757575);
          final dateStr = _formatDate(file['upload_date']);
          final rawUrl = file['file'] as String? ?? '';
          String fileUrl = '';
          if (rawUrl.isNotEmpty) {
            if (rawUrl.startsWith('http')) {
              try {
                final uri = Uri.parse(rawUrl);
                fileUrl = uri.replace(host: '10.0.2.2', port: 8000).toString();
              } catch (_) { fileUrl = rawUrl; }
            } else {
              fileUrl = '${ApiEndpoints.baseUrl}$rawUrl';
            }
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                child: Icon(Iconsax.document_text, color: color, size: 22),
              ),
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: DoctorColors.textPrimary)),
              subtitle: Text(dateStr, style: const TextStyle(color: DoctorColors.textSecondary, fontSize: 12)),
              trailing: fileUrl.isEmpty
                  ? const SizedBox()
                  : GestureDetector(
                      onTap: () => _openFile(context, fileUrl, label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Iconsax.export_2, color: color, size: 14),
                          const SizedBox(width: 4),
                          Text('Ouvrir', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 50), duration: 300.ms);
        },
      ),
    );
  }
}

// ─── Tab 2: Measurements ──────────────────────────────────────────────────────
class _MeasurementsTab extends StatelessWidget {
  final Map<String, dynamic>? measurements;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  const _MeasurementsTab({
    required this.measurements,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: DoctorColors.primary));
    if (error != null) return _ErrorState(message: error!, onRetry: onRefresh);
    if (measurements == null || measurements!.isEmpty) {
      return const _EmptyState(icon: Iconsax.activity, message: 'Aucune mesure disponible pour cette patiente');
    }

    final data = measurements!;
    final items = <_VitalItem>[
      if (data['weight'] != null)
        _VitalItem(icon: Iconsax.weight, label: 'Poids', value: '${data['weight']}', unit: 'kg', color: const Color(0xFF6C63FF)),
      if (data['bmi'] != null)
        _VitalItem(icon: Iconsax.chart_2, label: 'IMC', value: '${data['bmi']}', unit: '', color: const Color(0xFF00BFA5)),
      if (data['glycemia_informations'] != null)
        _VitalItem(
          icon: Iconsax.drop,
          label: 'Glycémie',
          value: '${data['glycemia_informations']['value1'] ?? '--'}',
          unit: '${data['glycemia_informations']['unit'] ?? ''}',
          color: const Color(0xFFFF8F00),
        ),
      if (data['blood_pressure'] != null)
        _VitalItem(
          icon: Iconsax.heart,
          label: 'Tension artérielle',
          value: '${data['blood_pressure']['value1'] ?? '--'}/${data['blood_pressure']['value2'] ?? '--'}',
          unit: 'mmHg',
          color: const Color(0xFFE53935),
        ),
      if (data['heart_rate'] != null)
        _VitalItem(
          icon: Iconsax.activity,
          label: 'Rythme cardiaque',
          value: '${data['heart_rate']['value1'] ?? '--'}',
          unit: 'bpm',
          color: const Color(0xFFE91E63),
        ),
      if (data['body_temp'] != null)
        _VitalItem(
          icon: Iconsax.health,
          label: 'Température',
          value: '${data['body_temp']['value1'] ?? '--'}',
          unit: '°C',
          color: const Color(0xFF1E88E5),
        ),
      if (data['pregnancy_week'] != null)
        _VitalItem(
          icon: Iconsax.calendar,
          label: 'Semaine de grossesse',
          value: '${data['pregnancy_week']}',
          unit: 'sem',
          color: const Color(0xFF43A047),
        ),
    ];

    if (items.isEmpty) {
      return const _EmptyState(icon: Iconsax.activity, message: 'Aucune mesure disponible pour cette patiente');
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: DoctorColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DoctorColors.primary.withAlpha(200), DoctorColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Iconsax.activity, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Mesures actuelles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Dernières valeurs enregistrées', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              ]),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            // Grid of vital cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _VitalCard(item: items[i])
                  .animate().fadeIn(delay: Duration(milliseconds: i * 80), duration: 300.ms)
                  .slideY(begin: 0.15, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalItem {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _VitalItem({required this.icon, required this.label, required this.value, required this.unit, required this.color});
}

class _VitalCard extends StatelessWidget {
  final _VitalItem item;
  const _VitalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: item.color.withAlpha(30), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: item.color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      item.value,
                      style: TextStyle(color: item.color, fontWeight: FontWeight.bold, fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.unit.isNotEmpty) ...[
                    const SizedBox(width: 2),
                    Text(item.unit, style: TextStyle(color: item.color.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
              Text(item.label, style: const TextStyle(color: DoctorColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Treatments ────────────────────────────────────────────────────────
class _TreatmentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> treatments;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  const _TreatmentsTab({
    required this.treatments,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  String _formatDate(dynamic d) {
    if (d == null) return '--';
    try { return DateFormat('dd/MM/yyyy', 'fr').format(DateTime.parse(d.toString())); } catch (_) { return d.toString(); }
  }

  bool _isActive(Map<String, dynamic> t) {
    final end = t['end_date'];
    if (end == null) return true;
    try { return DateTime.parse(end.toString()).isAfter(DateTime.now()); } catch (_) { return true; }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: DoctorColors.primary));
    if (error != null) return _ErrorState(message: error!, onRetry: onRefresh);
    if (treatments.isEmpty) {
      return const _EmptyState(icon: Iconsax.health, message: 'Aucun traitement en cours pour cette patiente');
    }

    final active = treatments.where(_isActive).toList();
    final past = treatments.where((t) => !_isActive(t)).toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: DoctorColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF43A047).withAlpha(200), const Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Iconsax.health, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${active.length} traitement${active.length > 1 ? 's' : ''} en cours',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${treatments.length} traitement${treatments.length > 1 ? 's' : ''} au total',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ).animate().fadeIn(duration: 300.ms),

            if (active.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionTitle(icon: Iconsax.tick_circle, label: 'Traitements actifs'),
              const SizedBox(height: 10),
              ...active.asMap().entries.map((e) => _TreatmentCard(
                treatment: e.value,
                isActive: true,
                formatDate: _formatDate,
              ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60), duration: 300.ms)),
            ],

            if (past.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionTitle(icon: Iconsax.clock, label: 'Traitements passés'),
              const SizedBox(height: 10),
              ...past.asMap().entries.map((e) => _TreatmentCard(
                treatment: e.value,
                isActive: false,
                formatDate: _formatDate,
              ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60), duration: 300.ms)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final Map<String, dynamic> treatment;
  final bool isActive;
  final String Function(dynamic) formatDate;

  const _TreatmentCard({required this.treatment, required this.isActive, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final med = treatment['medication'] as Map? ?? {};
    final name = med['commercial_name']?.toString() ?? med['name']?.toString() ?? 'Médicament inconnu';
    final form = med['form']?.toString() ?? '';
    final dosage = med['dosage']?.toString() ?? '';
    final dose = treatment['dose']?.toString() ?? '';
    final freq = treatment['frequency']?.toString() ?? '';
    final startDate = formatDate(treatment['start_date']);
    final endDate = formatDate(treatment['end_date']);
    final schedules = treatment['schedules'] as List? ?? [];

    final activeColor = isActive ? const Color(0xFF43A047) : const Color(0xFF9E9E9E);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: activeColor.withAlpha(60), width: 1.5),
        boxShadow: [BoxShadow(color: activeColor.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: activeColor.withAlpha(15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: activeColor.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: Icon(Iconsax.health, color: activeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: DoctorColors.textPrimary, fontSize: 14)),
                if (form.isNotEmpty || dosage.isNotEmpty)
                  Text('$form${dosage.isNotEmpty ? ' – $dosage' : ''}',
                      style: const TextStyle(color: DoctorColors.textSecondary, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isActive ? 'Actif' : 'Terminé',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _InfoRow(icon: Iconsax.weight, label: 'Dose', value: dose),
              if (freq.isNotEmpty) _InfoRow(icon: Iconsax.clock, label: 'Fréquence', value: freq),
              _InfoRow(icon: Iconsax.calendar, label: 'Début', value: startDate),
              if (treatment['end_date'] != null)
                _InfoRow(icon: Iconsax.calendar_1, label: 'Fin', value: endDate),
              if (schedules.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Iconsax.notification, size: 14, color: DoctorColors.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Horaires : ', style: TextStyle(color: DoctorColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: schedules.map((s) {
                        final time = (s is Map) ? s['dose_time']?.toString() ?? '' : '';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(time, style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty || value == '--') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: DoctorColors.textSecondary),
        const SizedBox(width: 6),
        Text('$label : ', style: const TextStyle(color: DoctorColors.textSecondary, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(color: DoctorColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

// ─── Shared error state ───────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Iconsax.warning_2, color: DoctorColors.error, size: 48),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: DoctorColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(backgroundColor: DoctorColors.primary),
          child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
        ),
      ]),
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

// ─── Full-screen image viewer for doctor ─────────────────────────────────────
class _DoctorImageViewerScreen extends StatelessWidget {
  final String url;
  final String name;
  const _DoctorImageViewerScreen({required this.url, required this.name});

  static Future<Uint8List> _fetchBytes(String url) async {
    final token = await const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ).read(key: StorageKeys.accessToken);
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      validateStatus: (s) => s != null && s < 500,
    ));
    final resp = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
    return Uint8List.fromList(resp.data!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _fetchBytes(url),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Iconsax.warning_2, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Erreur de chargement',
                    style: const TextStyle(color: Colors.white)),
              ]),
            );
          }
          return InteractiveViewer(
            child: Center(
              child: Image.memory(snap.data!, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
