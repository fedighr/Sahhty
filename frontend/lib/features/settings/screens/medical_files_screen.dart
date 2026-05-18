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

// ─── Screen ───────────────────────────────────────────────────────────────────
class MedicalFilesScreen extends ConsumerStatefulWidget {
  const MedicalFilesScreen({super.key});

  @override
  ConsumerState<MedicalFilesScreen> createState() => _MedicalFilesScreenState();
}

class _MedicalFilesScreenState extends ConsumerState<MedicalFilesScreen> {
  bool _uploading = false;

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dossier médical', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          // Gradient background
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
            child: Column(
              children: [
                // ── Header stats ──
                _buildHeader(asyncFiles).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // ── File list ──
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: asyncFiles.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (e, _) => _buildError(e.toString(), patientId),
                      data: (files) => files.isEmpty
                          ? _buildEmpty()
                          : _buildList(files),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // FAB upload
      floatingActionButton: _uploading
          ? null
          : FloatingActionButton.extended(
              onPressed: _pickAndUpload,
              backgroundColor: AppColors.primary,
              icon: const Icon(Iconsax.document_upload, color: Colors.white),
              label: const Text('Ajouter un fichier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
    );
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
