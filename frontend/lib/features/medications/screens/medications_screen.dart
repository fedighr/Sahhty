import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/medications/widgets/interaction_helpers.dart';
import 'package:sahhty/features/medications/widgets/medication_detail_sheet.dart';
import 'package:sahhty/features/medications/widgets/compare_tab.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Treatments state ─────────────────────────────────────────────
  List<dynamic> _treatments = [];
  bool _loadingTreatments = true;
  String? _treatmentsError;

  // ── Search state ─────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;
  String? _searchError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadTreatments();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Load treatments from backend ─────────────────────────────────
  Future<void> _loadTreatments() async {
    setState(() { _loadingTreatments = true; _treatmentsError = null; });
    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) {
      setState(() { _loadingTreatments = false; _treatmentsError = 'ID patient non trouvé'; });
      return;
    }
    final result = await ref.read(medicationServiceProvider).getTreatmentsByPatientId(patientId);
    if (!mounted) return;
    setState(() {
      _loadingTreatments = false;
      if (result['success'] == true) {
        final raw = result['treatments'];
        if (raw is Map) {
          _treatments = raw.values.toList();
        } else if (raw is List) {
          _treatments = raw;
        } else {
          _treatments = [];
        }
      } else {
        // 404 means no treatments → empty list, not an error
        final msg = result['message']?.toString() ?? '';
        if (msg.toLowerCase().contains('no treatments') || msg.toLowerCase().contains('not found')) {
          _treatments = [];
        } else {
          _treatmentsError = msg.isEmpty ? 'Erreur' : msg;
        }
      }
    });
  }

  // ── Search medications from backend ──────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() { _searchResults = []; _searchError = null; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final result = await ref.read(medicationServiceProvider).searchMedications(query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (result['results'] != null) {
        _searchResults = result['results'] as List<dynamic>;
        _searchError = null;
      } else if (result['detail'] != null) {
        _searchResults = [];
        final detail = result['detail'].toString();
        if (detail.toLowerCase().contains('no medications')) {
          _searchError = null;
        } else {
          _searchError = detail;
        }
      } else {
        _searchResults = [];
        _searchError = null;
      }
    });
  }

  Future<void> _deleteTreatment(int treatmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le traitement'),
        content: const Text('Voulez-vous vraiment supprimer ce traitement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(medicationServiceProvider).deleteTreatmentById(treatmentId);
    _loadTreatments();
  }

  // ── Show medication detail (with interactions) before add ──────────
  void _onSearchResultTapped(Map<String, dynamic> medication) async {
    final medId = medication['id'] as int?;
    if (medId == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final detail = await ref.read(medicationServiceProvider).getMedicationById(medId);
    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading

    final detailMed = detail['medication'] as Map<String, dynamic>? ?? medication;
    final pregnancyData = detail['pregnancy_data'] as Map<String, dynamic>?;
    final interactions = detail['medication_interactions'] as List<dynamic>? ?? [];

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicationDetailSheet(
        medication: detailMed,
        pregnancyData: pregnancyData,
        interactions: interactions,
        onAddTreatment: () {
          Navigator.pop(context); // Close detail sheet
          _showAddTreatmentSheet(medication);
        },
      ),
    );
  }

  void _showAddTreatmentSheet(Map<String, dynamic> medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTreatmentSheet(
        medication: medication,
        patientId: int.tryParse(ref.read(authProvider).patientId ?? '') ?? 0,
        medicationService: ref.read(medicationServiceProvider),
        onCreated: () {
          _loadTreatments();
          _tabCtrl.animateTo(0);
        },
      ),
    );
  }

  // ── Show treatment detail bottom sheet ────────────────────────────
  void _onTreatmentTapped(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TreatmentDetailSheet(treatment: t),
    );
  }

  String _frequencyLabel(String freq) {
    switch (freq.toUpperCase()) {
      case 'DAILY': return 'Chaque jour';
      case 'TWICE_DAILY': return '2 fois / jour';
      case 'WEEKLY': return 'Chaque semaine';
      case 'AS_NEEDED': return 'Si besoin';
      default: return freq;
    }
  }

  bool _isActive(Map<String, dynamic> t) {
    final end = t['end_date'];
    if (end == null) return true;
    final endDate = DateTime.tryParse(end.toString());
    return endDate != null && endDate.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médicaments'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Traitements', icon: Icon(Icons.medication_outlined, size: 20)),
            Tab(text: 'Rechercher', icon: Icon(Icons.search_outlined, size: 20)),
            Tab(text: 'Comparer', icon: Icon(Icons.compare_arrows, size: 20)),
          ],
        ),
      ),
      body: Stack(
        children: [
          const FloatingParticles(particleCount: 8, maxOpacity: 0.08),
          TabBarView(
            controller: _tabCtrl,
            children: [
              _buildTreatmentsTab(),
              _buildSearchTab(),
              CompareTab(medicationService: ref.read(medicationServiceProvider)),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TAB 1 — Treatments
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTreatmentsTab() {
    if (_loadingTreatments) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_treatmentsError != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 8),
          Text(_treatmentsError!, style: const TextStyle(color: AppColors.error)),
          TextButton(onPressed: _loadTreatments, child: const Text('Réessayer')),
        ]),
      );
    }
    if (_treatments.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('💊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Aucun traitement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Aucun médicament prescrit pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _tabCtrl.animateTo(1),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Rechercher un médicament'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(240, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]).animate().fadeIn(),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTreatments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _treatments.length,
        itemBuilder: (context, i) {
          final t = _treatments[i];
          return _buildTreatmentCard(t, i).animate().fadeIn(delay: (80 * i).ms).slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildTreatmentCard(dynamic t, int index) {
    if (t is! Map<String, dynamic>) return const SizedBox.shrink();
    final med = t['medication'] as Map<String, dynamic>?;
    final schedules = t['schedules'] as List<dynamic>? ?? [];
    final active = _isActive(t);
    final interactions = t['interactions'] as List<dynamic>? ?? [];

    // Find the worst interaction
    int worstPriority = 0;
    for (final inter in interactions) {
      if (inter is Map<String, dynamic>) {
        final p = InteractionHelpers.severityPriority(inter['severity']?.toString());
        if (p > worstPriority) {
          worstPriority = p;
        }
      }
    }

    return GestureDetector(
      onTap: () => _onTreatmentTapped(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: worstPriority >= 4
                ? AppColors.riskHigh.withAlpha(64)
                : active
                    ? AppColors.primary.withAlpha(38)
                    : const Color(0xFFE0E0E0),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('💊', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med?['commercial_name'] ?? med?['name'] ?? 'Médicament inconnu',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (med?['name'] != null && med?['commercial_name'] != null)
                        Text(med!['name'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.success.withAlpha(25) : AppColors.textLight.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    active ? 'Actif' : 'Terminé',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.success : AppColors.textLight),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteTreatment(t['id'] as int),
                  child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.straighten_outlined, t['dose'] ?? '--'),
                const SizedBox(width: 8),
                _infoChip(Icons.repeat, _frequencyLabel(t['frequency'] ?? '')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${t['start_date'] ?? '--'} → ${t['end_date'] ?? 'En cours'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            if (schedules.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Horaires :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: schedules.map((s) {
                  final time = s['dose_time'] ?? '--';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(time.toString(), style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            // ── Pregnancy risk badge ──────
            if (t['pregnancy_data'] != null && t['pregnancy_data'] is Map<String, dynamic>) ...[
              const SizedBox(height: 10),
              _buildPregnancyRiskBadge(t['pregnancy_data'] as Map<String, dynamic>),
            ],
            // ── Interactions badges ──────
            if (interactions.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInteractionsBadges(interactions),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Voir détails', style: TextStyle(fontSize: 11, color: AppColors.primary.withAlpha(153), fontWeight: FontWeight.w500)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary.withAlpha(153)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionsBadges(List<dynamic> interactions) {
    final sorted = List<dynamic>.from(interactions);
    sorted.sort((a, b) {
      final pa = InteractionHelpers.severityPriority((a as Map<String, dynamic>)['severity']?.toString());
      final pb = InteractionHelpers.severityPriority((b as Map<String, dynamic>)['severity']?.toString());
      return pb.compareTo(pa);
    });

    final shown = sorted.take(3).toList();
    final remaining = sorted.length - shown.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...shown.map((i) {
          final inter = i as Map<String, dynamic>;
          final severity = inter['severity']?.toString();
          final color = InteractionHelpers.severityColor(severity);
          final userMed = inter['user_medication']?.toString() ?? '?';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(51)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(InteractionHelpers.severityIcon(severity), size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  '⇌ $userMed',
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remaining',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TAB 2 — Search
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un médicament (nom, DCI...)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else if (_searchError != null)
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(_searchError!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
              ]),
            ),
          )
        else if (_searchCtrl.text.isEmpty)
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('💊', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text('Recherche de médicaments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Tapez au moins 2 caractères pour chercher',
                    style: TextStyle(color: AppColors.textSecondary.withAlpha(178), fontSize: 13)),
                const SizedBox(height: 8),
                Text('Appuyez sur un résultat pour voir les détails',
                    style: TextStyle(color: AppColors.primary.withAlpha(128), fontSize: 12)),
              ]).animate().fadeIn(),
            ),
          )
        else if (_searchResults.isEmpty && _searchCtrl.text.length >= 2)
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text('Aucun résultat trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchResults.length,
              itemBuilder: (context, i) {
                final med = _searchResults[i] as Map<String, dynamic>;
                return _buildSearchResultCard(med, i);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> med, int index) {
    final name = (med['commercial_name'] ?? med['name'] ?? 'Inconnu').toString();
    final dci = (med['dci'] ?? '').toString();
    final form = (med['form'] ?? '').toString();
    final dosage = (med['dosage'] ?? '').toString();
    final price = med['public_price'];
    final category = (med['category'] ?? '').toString();

    return GestureDetector(
      onTap: () => _onSearchResultTapped(med),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('💊', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (dci.isNotEmpty)
                        Text(dci, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$price DT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ),
              ],
            ),
            if (form.isNotEmpty || dosage.isNotEmpty || category.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  if (form.isNotEmpty) _searchChip(Icons.local_pharmacy_outlined, form),
                  if (dosage.isNotEmpty) _searchChip(Icons.straighten_outlined, dosage),
                  if (category.isNotEmpty) _searchChip(Icons.category_outlined, category),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Voir détails & interactions', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: (60 * index).ms).slideX(begin: 0.05),
    );
  }

  Widget _searchChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPregnancyRiskBadge(Map<String, dynamic> pregnancyData) {
    final trimesterRisk = pregnancyData['trimester_risk'] as String?;
    final currentTrimester = pregnancyData['current_trimester'] as String?;
    if (trimesterRisk == null) return const SizedBox.shrink();

    final color = InteractionHelpers.pregnancyRiskColor(trimesterRisk);
    final icon = InteractionHelpers.pregnancyRiskIcon(trimesterRisk);
    final riskLabel = InteractionHelpers.pregnancyRiskLabel(trimesterRisk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤰', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$currentTrimester : $riskLabel', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: color),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ADD TREATMENT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════
class _AddTreatmentSheet extends StatefulWidget {
  final Map<String, dynamic> medication;
  final int patientId;
  final dynamic medicationService;
  final VoidCallback onCreated;

  const _AddTreatmentSheet({
    required this.medication,
    required this.patientId,
    required this.medicationService,
    required this.onCreated,
  });

  @override
  State<_AddTreatmentSheet> createState() => _AddTreatmentSheetState();
}

class _AddTreatmentSheetState extends State<_AddTreatmentSheet> {
  final _doseCtrl = TextEditingController();
  String _frequency = 'DAILY';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final List<TimeOfDay> _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0)];
  bool _submitting = false;
  String? _error;

  final _frequencies = const {
    'DAILY': 'Chaque jour',
    'TWICE_DAILY': '2 fois / jour',
    'WEEKLY': 'Chaque semaine',
    'AS_NEEDED': 'Si besoin',
  };

  @override
  void dispose() {
    _doseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(context: context, initialTime: _scheduleTimes[index]);
    if (picked != null) setState(() => _scheduleTimes[index] = picked);
  }

  void _addScheduleTime() {
    setState(() => _scheduleTimes.add(const TimeOfDay(hour: 12, minute: 0)));
  }

  void _removeScheduleTime(int index) {
    if (_scheduleTimes.length > 1) {
      setState(() => _scheduleTimes.removeAt(index));
    }
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _submit() async {
    if (_doseCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer la dose');
      return;
    }
    setState(() { _submitting = true; _error = null; });

    final data = {
      'treatment': {
        'start_date': _formatDate(_startDate),
        if (_endDate != null) 'end_date': _formatDate(_endDate!),
        'dose': _doseCtrl.text.trim(),
        'frequency': _frequency,
        'patient_id': widget.patientId,
        'medication_id': widget.medication['id'],
      },
      'schedules': _scheduleTimes.map((t) => {'dose_time': _formatTime(t)}).toList(),
    };

    final result = await widget.medicationService.createTreatmentWithSchedules(data);
    if (!mounted) return;

    if (result['success'] == true || result['treatment'] != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Traitement ajouté avec succès'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      widget.onCreated();
    } else {
      setState(() {
        _submitting = false;
        _error = result['message']?.toString() ?? 'Erreur lors de la création';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medName = (widget.medication['commercial_name'] ?? widget.medication['name'] ?? 'Médicament').toString();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Ajouter un traitement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(medName, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),

            // Dose
            TextField(
              controller: _doseCtrl,
              decoration: const InputDecoration(
                labelText: 'Dose (ex: 500mg, 1 comprimé...)',
                prefixIcon: Icon(Icons.straighten_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Frequency
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                prefixIcon: Icon(Icons.repeat, color: AppColors.primary),
              ),
              items: _frequencies.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) { if (v != null) setState(() => _frequency = v); },
            ),
            const SizedBox(height: 16),

            // Dates row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date début',
                        prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                      ),
                      child: Text(_formatDate(_startDate), style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEndDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date fin',
                        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                        suffixIcon: _endDate != null
                            ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _endDate = null))
                            : null,
                      ),
                      child: Text(
                        _endDate != null ? _formatDate(_endDate!) : 'Optionnel',
                        style: TextStyle(fontSize: 14, color: _endDate != null ? AppColors.textPrimary : AppColors.textLight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Schedule times
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Horaires de prise', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: _addScheduleTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Ajouter', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_scheduleTimes.length, (i) {
              final t = _scheduleTimes[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickTime(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withAlpha(128),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.primaryDark)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_scheduleTimes.length > 1) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeScheduleTime(i),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.error.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Ajouter le traitement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TREATMENT DETAIL BOTTOM SHEET (with interactions)
// ═══════════════════════════════════════════════════════════════════════
class _TreatmentDetailSheet extends StatelessWidget {
  final Map<String, dynamic> treatment;
  const _TreatmentDetailSheet({required this.treatment});

  @override
  Widget build(BuildContext context) {
    final med = treatment['medication'] as Map<String, dynamic>?;
    final schedules = treatment['schedules'] as List<dynamic>? ?? [];
    final pregnancyData = treatment['pregnancy_data'] as Map<String, dynamic>?;
    final interactions = treatment['interactions'] as List<dynamic>? ?? [];

    final medName = (med?['commercial_name'] ?? med?['name'] ?? 'Médicament inconnu').toString();
    final medDci = (med?['dci'] ?? '').toString();
    final medForm = (med?['form'] ?? '').toString();
    final medDosage = (med?['dosage'] ?? '').toString();
    final medPrice = med?['public_price'];

    final dose = (treatment['dose'] ?? '--').toString();
    final freq = (treatment['frequency'] ?? '').toString();
    final startDate = (treatment['start_date'] ?? '--').toString();
    final endDate = treatment['end_date']?.toString();

    String freqLabel;
    switch (freq.toUpperCase()) {
      case 'DAILY': freqLabel = 'Chaque jour'; break;
      case 'TWICE_DAILY': freqLabel = '2 fois / jour'; break;
      case 'WEEKLY': freqLabel = 'Chaque semaine'; break;
      case 'AS_NEEDED': freqLabel = 'Si besoin'; break;
      default: freqLabel = freq;
    }

    // Sort interactions by severity
    final sortedInteractions = List<dynamic>.from(interactions);
    sortedInteractions.sort((a, b) {
      final pa = InteractionHelpers.severityPriority((a as Map<String, dynamic>)['severity']?.toString());
      final pb = InteractionHelpers.severityPriority((b as Map<String, dynamic>)['severity']?.toString());
      return pb.compareTo(pa);
    });

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight, borderRadius: BorderRadius.circular(2))),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication header
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: Text('💊', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(medName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            if (medDci.isNotEmpty)
                              Text(medDci, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Info grid
                  _DetailRow(icon: Icons.straighten_outlined, label: 'Dose', value: dose),
                  _DetailRow(icon: Icons.repeat, label: 'Fréquence', value: freqLabel),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date début', value: startDate),
                  _DetailRow(icon: Icons.event_outlined, label: 'Date fin', value: endDate ?? 'En cours'),
                  if (medForm.isNotEmpty) _DetailRow(icon: Icons.local_pharmacy_outlined, label: 'Forme', value: medForm),
                  if (medDosage.isNotEmpty) _DetailRow(icon: Icons.science_outlined, label: 'Dosage', value: medDosage),
                  if (medPrice != null) _DetailRow(icon: Icons.attach_money, label: 'Prix public', value: '$medPrice DT'),

                  if (schedules.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Horaires de prise', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: schedules.map((s) {
                        final time = (s['dose_time'] ?? '--').toString();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withAlpha(38)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(time, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // ── Pregnancy risk ──────────────────────
                  if (pregnancyData != null) ...[
                    const SizedBox(height: 20),
                    _buildPregnancyRiskSection(pregnancyData),
                  ],

                  // ── Interactions ────────────────────────
                  if (sortedInteractions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildInteractionsSection(sortedInteractions),
                  ],

                  if (sortedInteractions.isEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withAlpha(38)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aucune interaction détectée avec vos traitements actuels',
                              style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPregnancyRiskSection(Map<String, dynamic> data) {
    final dciRisk = data['dci_risk'] as Map<String, dynamic>?;
    final trimesterRisk = data['trimester_risk'] as String?;
    final currentTrimester = data['current_trimester'] as String?;
    if (trimesterRisk == null || dciRisk == null) return const SizedBox.shrink();

    final riskColor = InteractionHelpers.pregnancyRiskColor(trimesterRisk);
    final riskIcon = InteractionHelpers.pregnancyRiskIcon(trimesterRisk);
    final riskLabel = InteractionHelpers.pregnancyRiskLabel(trimesterRisk);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withAlpha(64)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤰', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Risque grossesse', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: riskColor)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(riskIcon, size: 20, color: riskColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$currentTrimester : $riskLabel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: riskColor)),
              ),
            ],
          ),
          if (dciRisk['overall'] != null) ...[
            const SizedBox(height: 6),
            Text('Statut global : ${InteractionHelpers.pregnancyRiskLabel(dciRisk['overall']?.toString())}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (dciRisk['summary'] != null && dciRisk['summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(dciRisk['summary'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionsSection(List<dynamic> interactions) {
    final hasHighRisk = interactions.any((i) =>
        InteractionHelpers.severityPriority((i as Map<String, dynamic>)['severity']?.toString()) >= 4);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasHighRisk ? AppColors.riskHigh.withAlpha(8) : AppColors.riskMedium.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasHighRisk ? AppColors.riskHigh.withAlpha(38) : AppColors.riskMedium.withAlpha(38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasHighRisk ? Icons.warning_amber_rounded : Icons.compare_arrows,
                size: 20,
                color: hasHighRisk ? AppColors.riskHigh : AppColors.riskMedium,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Interactions médicamenteuses (${interactions.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: hasHighRisk ? AppColors.riskHigh : AppColors.riskMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...interactions.map((i) {
            final inter = i as Map<String, dynamic>;
            final severity = inter['severity']?.toString();
            final color = InteractionHelpers.severityColor(severity);
            final userMed = inter['user_medication']?.toString() ?? 'Inconnu';
            final description = inter['description'] ?? inter['interaction'] ?? '';
            final dci1 = inter['dci1']?.toString() ?? '';
            final dci2 = inter['dci2']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(51)),
                boxShadow: [BoxShadow(color: color.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(InteractionHelpers.severityIcon(severity), size: 16, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Avec : $userMed',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                      InteractionHelpers.severityBadge(severity, compact: true),
                    ],
                  ),
                  if (dci1.isNotEmpty && dci2.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$dci1 ↔ $dci2',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (description.toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description.toString(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

