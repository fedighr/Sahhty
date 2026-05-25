import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sahhty/core/constants/api_endpoints.dart';
import 'package:sahhty/data/services/dio_client.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/services/websocket_service.dart';
import 'package:sahhty/core/providers/websocket_provider.dart';

// ─── Attachment type metadata ─────────────────────────────────────────────────
class _TypeMeta {
  final String code;
  final String label;
  final IconData icon;
  final Color color;
  const _TypeMeta(this.code, this.label, this.icon, this.color);
}

const _types = [
  _TypeMeta('REPORT',       'Compte rendu',        Iconsax.document_text,  Color(0xFF6C63FF)),
  _TypeMeta('ULTRASOUND',   'Échographie',          Iconsax.health,         Color(0xFF00BFA5)),
  _TypeMeta('BLOOD_TEST',   'Analyse de sang',      Iconsax.drop,           Color(0xFFE53935)),
  _TypeMeta('URINE_TEST',   'Analyse d\'urine',     Iconsax.drop,           Color(0xFFFF8F00)),
  _TypeMeta('PRESCRIPTION', 'Ordonnance',           Iconsax.receipt_item,   Color(0xFF1E88E5)),
  _TypeMeta('VACCINATION',  'Vaccination',          Iconsax.shield_tick,    Color(0xFF43A047)),
  _TypeMeta('ECHO',         'Échocardiographie',    Iconsax.heart,          Color(0xFFE91E63)),
  _TypeMeta('OTHER',        'Autre',                Iconsax.document,       Color(0xFF757575)),
];

_TypeMeta _metaFor(String code) =>
    _types.firstWhere((t) => t.code == code, orElse: () => _types.last);

// ─── State provider ───────────────────────────────────────────────────────────
final _medFilesProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, patientId) async {
    final result = await ref.read(medicalFileServiceProvider).getPatientMedicalFiles(patientId);
    // Backend returns paginated response: {count, next, previous, results: [...]}
    if (result.containsKey('results')) {
      return List<Map<String, dynamic>>.from(result['results'] ?? []);
    }
    // Fallback: legacy {success, medical_files} format
    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['medical_files'] ?? []);
    }
    throw Exception(result['message']?.toString() ?? 'Erreur lors du chargement');
  },
);

final _pendingRequestsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, patientId) async {
    final result = await ref.read(medicalFileServiceProvider).getPatientDoctorsRequests(patientId);
    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['doctors'] ?? []);
    }
    return [];
  },
);

final _authorizedDoctorsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, int>(
  (ref, patientId) async {
    final result = await ref.read(medicalFileServiceProvider).getPatientDoctors(patientId);
    if (result['success'] == true) {
      return List<Map<String, dynamic>>.from(result['doctors'] ?? []);
    }
    return [];
  },
);
class MedicalFilesScreen extends ConsumerStatefulWidget {
  const MedicalFilesScreen({super.key});

  @override
  ConsumerState<MedicalFilesScreen> createState() => _MedicalFilesScreenState();
}

class _MedicalFilesScreenState extends ConsumerState<MedicalFilesScreen> with TickerProviderStateMixin {
  bool _uploading = false;
  late TabController _tabController;
  StreamSubscription<WsNotification>? _wsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenWs());
  }

  void _listenWs() {
    _wsSub = ref.read(webSocketServiceProvider).notifications.listen((n) {
      if (n.type == 'access_request' && mounted) {
        final patientId = _getPatientId();
        if (patientId != null) {
          ref.invalidate(_pendingRequestsProvider(patientId));
        }
        // Switch to access tab
        _tabController.animateTo(1);
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  int? _getPatientId() => int.tryParse(ref.read(authProvider).patientId ?? '');

  // ── Upload ─────────────────────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    final patientId = _getPatientId();
    if (patientId == null) {
      _showSnack('ID patient introuvable', isError: true);
      return;
    }

    // Choose type first
    final chosenType = await _showTypeDialog();
    if (chosenType == null || !mounted) return;

    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result == null || result.files.single.path == null || !mounted) return;

    final file = result.files.single;
    setState(() => _uploading = true);

    final uploadResult = await ref.read(medicalFileServiceProvider).createAttachment(
      patientId: patientId,
      type: chosenType,
      filePath: file.path!,
      fileName: file.name,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (uploadResult['success'] == true) {
      _showSnack('Fichier ajouté avec succès ✓');
      ref.invalidate(_medFilesProvider(patientId));
    } else {
      _showSnack(uploadResult['message'] ?? 'Erreur upload', isError: true);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteFile(Map<String, dynamic> attachment) async {
    final patientId = _getPatientId();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Iconsax.trash, color: AppColors.error, size: 40),
        title: const Text('Supprimer le fichier ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Le fichier "${_metaFor(attachment['type'] ?? 'OTHER').label}" sera définitivement supprimé.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref.read(medicalFileServiceProvider).deleteAttachment(attachment['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSnack('Fichier supprimé');
      if (patientId != null) ref.invalidate(_medFilesProvider(patientId));
    } else {
      _showSnack(result['message'] ?? 'Erreur suppression', isError: true);
    }
  }

  // ── Type picker dialog ──────────────────────────────────────────────────────
  Future<String?> _showTypeDialog() => showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Icon(Iconsax.document, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text('Type de document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _types.map((t) => GestureDetector(
              onTap: () => Navigator.pop(ctx, t.code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: t.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.color.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, color: t.color, size: 18),
                    const SizedBox(width: 6),
                    Text(t.label, style: TextStyle(color: t.color, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Iconsax.close_circle : Iconsax.tick_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final patientId = _getPatientId();
    if (patientId == null) {
      return const Scaffold(body: Center(child: Text('ID patient introuvable')));
    }

    final asyncFiles = ref.watch(_medFilesProvider(patientId));
    final asyncPending = ref.watch(_pendingRequestsProvider(patientId));
    final pendingCount = asyncPending.value?.length ?? 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dossier médical', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(text: 'Mes fichiers', icon: Icon(Iconsax.folder_open, size: 18)),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.people, size: 18),
                  const SizedBox(width: 6),
                  const Text('Accès médecins'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: Text('$pendingCount', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _pickAndUpload,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.add_circle, color: Colors.white, size: 22),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark, Color(0xFF6A1B4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            height: 220,
          ),
          const AnimatedBackground(showImage: true, imageOpacity: 0.05),
          const FloatingParticles(particleCount: 10, maxOpacity: 0.12),

          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: Files ──
                Column(
                  children: [
                    _buildHeader(asyncFiles).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F5FF),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: asyncFiles.when(
                          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          error: (e, _) => _buildError(e.toString(), patientId),
                          data: (files) => files.isEmpty ? _buildEmpty() : _buildList(files),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Tab 2: Access Management ──
                _buildAccessTab(patientId),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0 && !_uploading
            ? FloatingActionButton.extended(
                onPressed: _pickAndUpload,
                backgroundColor: AppColors.primary,
                icon: const Icon(Iconsax.document_upload, color: Colors.white),
                label: const Text('Ajouter un fichier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8))
            : const SizedBox.shrink(),
      ),
    );
  }

  // ── Access management tab ──────────────────────────────────────────────────
  Widget _buildAccessTab(int patientId) {
    final asyncPending = ref.watch(_pendingRequestsProvider(patientId));
    final asyncAuthorized = ref.watch(_authorizedDoctorsProvider(patientId));

    return Container(
      color: const Color(0xFFF8F5FF),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        physics: const BouncingScrollPhysics(),
        children: [
          // Pending requests section
          Row(
            children: [
              const Icon(Iconsax.timer_1, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text('Demandes en attente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              asyncPending.when(
                data: (list) => list.isEmpty ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                        child: Text('${list.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          asyncPending.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary))),
            error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error))),
            data: (pending) => pending.isEmpty
                ? _emptySection('Aucune demande en attente', Iconsax.timer_1, Colors.orange)
                : Column(
                    children: pending.map((doc) => _buildPendingCard(doc, patientId)).toList(),
                  ),
          ),

          const SizedBox(height: 28),

          // Authorized doctors section
          Row(
            children: [
              const Icon(Iconsax.tick_circle, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text('Médecins autorisés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          asyncAuthorized.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary))),
            error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppColors.error))),
            data: (doctors) => doctors.isEmpty
                ? _emptySection('Aucun médecin autorisé', Iconsax.people, AppColors.textLight)
                : Column(
                    children: doctors.map((doc) => _buildAuthorizedCard(doc, patientId)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptySection(String msg, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: color.withAlpha(120), size: 36),
            const SizedBox(height: 8),
            Text(msg, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> doc, int patientId) {
    final user = doc['user'] as Map<String, dynamic>? ?? {};
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final speciality = (doc['speciality'] as Map<String, dynamic>?)?['name'] ?? doc['speciality']?.toString() ?? '';
    final city = doc['ville'] ?? '';
    final doctorId = doc['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withAlpha(80), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.orange.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFB74D)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Iconsax.user, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. $name', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      if (speciality.isNotEmpty)
                        Text(speciality, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (city.isNotEmpty)
                        Text(city, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withAlpha(60)),
                  ),
                  child: const Text('En attente', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(doctorId, patientId),
                    icon: const Icon(Iconsax.close_circle, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withAlpha(60)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRequest(doctorId, patientId),
                    icon: const Icon(Iconsax.tick_circle, size: 16),
                    label: const Text('Autoriser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  Widget _buildAuthorizedCard(Map<String, dynamic> doc, int patientId) {
    final user = doc['user'] as Map<String, dynamic>? ?? {};
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final speciality = (doc['speciality'] as Map<String, dynamic>?)?['name'] ?? doc['speciality']?.toString() ?? '';
    final city = doc['ville'] ?? '';
    final doctorId = doc['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withAlpha(60), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.success.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withAlpha(180)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Iconsax.user, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. $name', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (speciality.isNotEmpty)
                    Text(speciality, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (city.isNotEmpty)
                    Text(city, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Autorisé', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Iconsax.close_circle, color: AppColors.error, size: 20),
              tooltip: 'Révoquer l\'accès',
              onPressed: () => _revokeAccess(doctorId, patientId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05);
  }

  Future<void> _acceptRequest(dynamic doctorId, int patientId) async {
    final result = await ref.read(medicalFileServiceProvider).acceptDoctorAccess(
      patientId: patientId,
      doctorId: doctorId,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      _showSnack('Accès accordé au médecin ✓');
      ref.invalidate(_pendingRequestsProvider(patientId));
      ref.invalidate(_authorizedDoctorsProvider(patientId));
    } else {
      _showSnack(result['message'] ?? 'Erreur', isError: true);
    }
  }

  Future<void> _rejectRequest(dynamic doctorId, int patientId) async {
    final result = await ref.read(medicalFileServiceProvider).revokeAccess(
      patientId: patientId,
      doctorId: doctorId,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      _showSnack('Demande refusée');
      ref.invalidate(_pendingRequestsProvider(patientId));
    } else {
      _showSnack(result['message'] ?? 'Erreur', isError: true);
    }
  }

  Future<void> _revokeAccess(dynamic doctorId, int patientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Iconsax.close_circle, color: AppColors.error, size: 40),
        title: const Text('Révoquer l\'accès ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Ce médecin ne pourra plus accéder à vos dossiers médicaux.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref.read(medicalFileServiceProvider).revokeAccess(
      patientId: patientId,
      doctorId: doctorId,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      _showSnack('Accès révoqué');
      ref.invalidate(_authorizedDoctorsProvider(patientId));
    } else {
      _showSnack(result['message'] ?? 'Erreur', isError: true);
    }
  }

  Widget _buildHeader(AsyncValue<List<Map<String, dynamic>>> asyncFiles) {
    final count = asyncFiles.value?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Iconsax.folder_open, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mon dossier médical',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$count document${count != 1 ? 's' : ''} enregistré${count != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.folder_open, size: 64, color: AppColors.primary.withAlpha(120)),
          ),
          const SizedBox(height: 20),
          const Text('Aucun document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Ajoutez vos résultats d\'examens,\nordonnances et autres documents médicaux.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _pickAndUpload,
            icon: const Icon(Iconsax.document_upload, size: 18),
            label: const Text('Ajouter un premier fichier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildError(String msg, int patientId) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.warning_2, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(_medFilesProvider(patientId)),
            icon: const Icon(Iconsax.refresh_2, size: 16),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> files) {
    // Group by type
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final f in files) {
      final type = f['type'] ?? 'OTHER';
      groups.putIfAbsent(type, () => []).add(f);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        // Summary chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups.entries.map((e) {
            final meta = _metaFor(e.key);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: meta.color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: meta.color.withAlpha(50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(meta.icon, size: 14, color: meta.color),
                  const SizedBox(width: 5),
                  Text('${e.value.length} ${meta.label}', style: TextStyle(color: meta.color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 20),

        // Individual cards
        ...files.asMap().entries.map((entry) {
          final idx = entry.key;
          final f = entry.value;
          return _FileCard(
            attachment: f,
            onDelete: () => _deleteFile(f),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 + idx * 60)).slideX(begin: 0.05);
        }),
      ],
    );
  }
}

// ─── File Card ────────────────────────────────────────────────────────────────
class _FileCard extends StatelessWidget {
  final Map<String, dynamic> attachment;
  final VoidCallback onDelete;

  const _FileCard({required this.attachment, required this.onDelete});

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _fileName(String? url) {
    if (url == null || url.isEmpty) return 'Fichier';
    return url.split('/').last.split('?').first;
  }


  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(attachment['type'] ?? 'OTHER');
    final rawUrl = attachment['file']?.toString() ?? '';
    // Normalize URL: always use 10.0.2.2:8000 as host for emulator
    String fileUrl = '';
    if (rawUrl.isNotEmpty) {
      if (rawUrl.startsWith('http')) {
        // Replace any host with 10.0.2.2:8000
        try {
          final uri = Uri.parse(rawUrl);
          fileUrl = uri.replace(host: '10.0.2.2', port: 8000).toString();
        } catch (_) {
          fileUrl = rawUrl;
        }
      } else {
        fileUrl = '${ApiEndpoints.baseUrl}$rawUrl';
      }
    }
    final name = _fileName(rawUrl);
    final dateStr = _formatDate(attachment['upload_date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // Show detail bottom sheet
            _showDetail(context, meta, fileUrl, name, dateStr);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [meta.color.withAlpha(30), meta.color.withAlpha(15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: meta.color.withAlpha(40)),
                  ),
                  child: Icon(meta.icon, color: meta.color, size: 24),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: meta.color.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(meta.label,
                                style: TextStyle(color: meta.color, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Iconsax.calendar, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.trash, color: Colors.grey, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Supprimer',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    const Icon(Iconsax.arrow_right_3, color: AppColors.textLight, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isImage(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.webp');
  }

  void _showDetail(BuildContext context, _TypeMeta meta, String fileUrl, String name, String dateStr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Preview or icon
            if (_isImage(fileUrl) && fileUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 160,
                  height: 120,
                  child: _ImageViewerScreen.buildThumbnail(fileUrl),
                ),
              )
            else
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: meta.color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(meta.icon, color: meta.color, size: 40),
            ),
            const SizedBox(height: 16),

            Text(name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: meta.color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(meta.label, style: TextStyle(color: meta.color, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.calendar, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(dateStr, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 24),

            // File URL info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.document_text, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileUrl.isNotEmpty ? fileUrl : 'Aucun fichier',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Iconsax.close_circle, size: 18),
                    label: const Text('Fermer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.textLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: fileUrl.isNotEmpty
                        ? () async {
                            Navigator.pop(ctx);
                            if (_isImage(fileUrl)) {
                              // Open image directly in Flutter viewer
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => _ImageViewerScreen(url: fileUrl, name: name),
                              ));
                            } else {
                              // Download non-image files and open with system app
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
                          }
                        : null,
                    icon: const Icon(Iconsax.export_2, size: 18),
                    label: const Text('Ouvrir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// ─── Full-screen image viewer ──────────────────────────────────────────────────
class _ImageViewerScreen extends StatelessWidget {
  final String url;
  final String name;
  const _ImageViewerScreen({required this.url, required this.name});

  /// Download image bytes via Dio with auth header
  static Future<Uint8List> _fetchBytes(String url) async {
    final token = await const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ).read(key: StorageKeys.accessToken);
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      validateStatus: (s) => s != null && s < 500,
    ));
    final response = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return Uint8List.fromList(response.data!);
  }

  /// Build a thumbnail for the bottom sheet preview
  static Widget buildThumbnail(String url) {
    return FutureBuilder<Uint8List>(
      future: _fetchBytes(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Icon(Iconsax.image, size: 40, color: AppColors.textLight));
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Center(
        child: FutureBuilder<Uint8List>(
          future: _fetchBytes(url),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              final errMsg = '${snapshot.error}';
              final isNotFound = errMsg.contains('404');
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isNotFound ? Iconsax.document_text : Iconsax.image,
                      size: 64,
                      color: Colors.white38,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isNotFound
                          ? 'Fichier introuvable sur le serveur'
                          : 'Impossible de charger le fichier',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isNotFound
                          ? 'Ce fichier n\'est plus disponible. Veuillez le supprimer et le re-téléverser depuis cet appareil.'
                          : errMsg,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.memory(snapshot.data!, fit: BoxFit.contain),
            );
          },
        ),
      ),
    );
  }
}
