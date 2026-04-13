import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/services/medication_service.dart';
import 'package:sahhty/features/medications/widgets/interaction_helpers.dart';

/// A tab that allows comparing two medications side by side
class CompareTab extends StatefulWidget {
  final MedicationService medicationService;

  const CompareTab({super.key, required this.medicationService});

  @override
  State<CompareTab> createState() => _CompareTabState();
}

class _CompareTabState extends State<CompareTab> {
  // ── Left medication ──
  final _leftSearchCtrl = TextEditingController();
  List<dynamic> _leftSearchResults = [];
  bool _leftSearching = false;
  Timer? _leftDebounce;
  Map<String, dynamic>? _leftMed; // from search result
  Map<String, dynamic>? _leftDetail; // full detail from API
  bool _leftLoading = false;

  // ── Right medication ──
  final _rightSearchCtrl = TextEditingController();
  List<dynamic> _rightSearchResults = [];
  bool _rightSearching = false;
  Timer? _rightDebounce;
  Map<String, dynamic>? _rightMed;
  Map<String, dynamic>? _rightDetail;
  bool _rightLoading = false;

  @override
  void dispose() {
    _leftSearchCtrl.dispose();
    _rightSearchCtrl.dispose();
    _leftDebounce?.cancel();
    _rightDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, bool isLeft) {
    final debounce = isLeft ? _leftDebounce : _rightDebounce;
    debounce?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        if (isLeft) {
          _leftSearchResults = [];
          _leftSearching = false;
        } else {
          _rightSearchResults = [];
          _rightSearching = false;
        }
      });
      return;
    }
    setState(() {
      if (isLeft) _leftSearching = true;
      else _rightSearching = true;
    });

    final newDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await widget.medicationService.searchMedications(query.trim());
      if (!mounted) return;
      setState(() {
        if (isLeft) {
          _leftSearching = false;
          _leftSearchResults = (result['results'] as List<dynamic>?) ?? [];
        } else {
          _rightSearching = false;
          _rightSearchResults = (result['results'] as List<dynamic>?) ?? [];
        }
      });
    });

    if (isLeft) _leftDebounce = newDebounce;
    else _rightDebounce = newDebounce;
  }

  Future<void> _selectMed(Map<String, dynamic> med, bool isLeft) async {
    setState(() {
      if (isLeft) {
        _leftMed = med;
        _leftSearchResults = [];
        _leftSearchCtrl.text = (med['commercial_name'] ?? med['name'] ?? '').toString();
        _leftLoading = true;
      } else {
        _rightMed = med;
        _rightSearchResults = [];
        _rightSearchCtrl.text = (med['commercial_name'] ?? med['name'] ?? '').toString();
        _rightLoading = true;
      }
    });

    final detail = await widget.medicationService.getMedicationById(med['id'] as int);
    if (!mounted) return;
    setState(() {
      if (isLeft) {
        _leftDetail = detail['success'] == true ? detail : null;
        _leftLoading = false;
      } else {
        _rightDetail = detail['success'] == true ? detail : null;
        _rightLoading = false;
      }
    });
  }

  void _clearSelection(bool isLeft) {
    setState(() {
      if (isLeft) {
        _leftMed = null;
        _leftDetail = null;
        _leftSearchCtrl.clear();
        _leftSearchResults = [];
      } else {
        _rightMed = null;
        _rightDetail = null;
        _rightSearchCtrl.clear();
        _rightSearchResults = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bothSelected = _leftMed != null && _rightMed != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withAlpha(15),
                  AppColors.primary.withAlpha(15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.compare_arrows, size: 36, color: AppColors.primary),
                SizedBox(height: 8),
                Text(
                  'Comparer deux médicaments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Recherchez et sélectionnez deux médicaments pour les comparer',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          // ── Two search fields side by side ──────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSearchColumn(true)),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchColumn(false)),
            ],
          ),
          const SizedBox(height: 24),

          // ── Comparison table ────────────────────────
          if (bothSelected && !_leftLoading && !_rightLoading)
            _buildComparisonView().animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

          if (bothSelected && (_leftLoading || _rightLoading))
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchColumn(bool isLeft) {
    final ctrl = isLeft ? _leftSearchCtrl : _rightSearchCtrl;
    final results = isLeft ? _leftSearchResults : _rightSearchResults;
    final searching = isLeft ? _leftSearching : _rightSearching;
    final selected = isLeft ? _leftMed : _rightMed;
    final loading = isLeft ? _leftLoading : _rightLoading;

    return Column(
      children: [
        // Label
        Text(
          isLeft ? 'Médicament 1' : 'Médicament 2',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isLeft ? AppColors.primary : AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),

        // Search or selected
        if (selected != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isLeft ? AppColors.primary : AppColors.accent).withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (isLeft ? AppColors.primary : AppColors.accent).withAlpha(38)),
            ),
            child: Column(
              children: [
                const Text('💊', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  (selected['commercial_name'] ?? selected['name'] ?? '').toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (loading) ...[
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _clearSelection(isLeft),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Changer',
                      style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          TextField(
            controller: ctrl,
            onChanged: (q) => _onSearchChanged(q, isLeft),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Chercher...',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: Icon(Icons.search, size: 18, color: isLeft ? AppColors.primary : AppColors.accent),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        ctrl.clear();
                        _onSearchChanged('', isLeft);
                      },
                    )
                  : null,
            ),
          ),
          if (searching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          if (results.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final med = results[i] as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      (med['commercial_name'] ?? med['name'] ?? '').toString(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      (med['dci'] ?? '').toString(),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectMed(med, isLeft),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildComparisonView() {
    final leftMed = _leftDetail?['medication'] as Map<String, dynamic>? ?? _leftMed ?? {};
    final rightMed = _rightDetail?['medication'] as Map<String, dynamic>? ?? _rightMed ?? {};
    final leftPreg = _leftDetail?['pregnancy_data'] as Map<String, dynamic>?;
    final rightPreg = _rightDetail?['pregnancy_data'] as Map<String, dynamic>?;
    final leftInteractions = _leftDetail?['medication_interactions'] as List<dynamic>? ?? [];
    final rightInteractions = _rightDetail?['medication_interactions'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // ── Basic Info Comparison ────
        _comparisonSection(
          title: 'Informations générales',
          icon: Icons.info_outline,
          rows: [
            _compRow('Nom', leftMed['name']?.toString(), rightMed['name']?.toString()),
            _compRow('Nom commercial', leftMed['commercial_name']?.toString(), rightMed['commercial_name']?.toString()),
            _compRow('DCI', leftMed['dci']?.toString(), rightMed['dci']?.toString()),
            _compRow('Forme', leftMed['form']?.toString(), rightMed['form']?.toString()),
            _compRow('Dosage', leftMed['dosage']?.toString(), rightMed['dosage']?.toString()),
            _compRow('Conditionnement', leftMed['package']?.toString(), rightMed['package']?.toString()),
          ],
        ),
        const SizedBox(height: 16),

        // ── Price Comparison ────
        _buildPriceComparison(leftMed, rightMed),
        const SizedBox(height: 16),

        // ── Pregnancy Risk Comparison ────
        if (leftPreg != null || rightPreg != null) ...[
          _buildPregnancyComparison(leftPreg, rightPreg, leftMed, rightMed),
          const SizedBox(height: 16),
        ],

        // ── Interactions Summary ────
        _buildInteractionsComparison(leftInteractions, rightInteractions, leftMed, rightMed),
      ],
    );
  }

  Widget _comparisonSection({required String title, required IconData icon, required List<Widget> rows}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          // Table header
          Row(
            children: [
              const SizedBox(width: 100),
              Expanded(
                child: Text('Méd. 1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary.withAlpha(178)), textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text('Méd. 2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent.withAlpha(204)), textAlign: TextAlign.center),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _compRow(String label, String? left, String? right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              left ?? '--',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              right ?? '--',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceComparison(Map<String, dynamic> leftMed, Map<String, dynamic> rightMed) {
    final leftPrice = double.tryParse(leftMed['public_price']?.toString() ?? '');
    final rightPrice = double.tryParse(rightMed['public_price']?.toString() ?? '');

    Color leftColor = AppColors.textPrimary;
    Color rightColor = AppColors.textPrimary;
    String leftIcon = '';
    String rightIcon = '';

    if (leftPrice != null && rightPrice != null) {
      if (leftPrice < rightPrice) {
        leftColor = AppColors.success;
        rightColor = AppColors.riskMedium;
        leftIcon = ' ✓';
        rightIcon = '';
      } else if (rightPrice < leftPrice) {
        rightColor = AppColors.success;
        leftColor = AppColors.riskMedium;
        rightIcon = ' ✓';
        leftIcon = '';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.attach_money, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Comparaison de prix', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: leftColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: leftColor.withAlpha(38)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        leftPrice != null ? '${leftPrice.toStringAsFixed(3)} DT$leftIcon' : 'N/A',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: leftColor),
                      ),
                      if (leftMed['tarif_reference'] != null)
                        Text('Réf: ${leftMed['tarif_reference']} DT',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: rightColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: rightColor.withAlpha(38)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        rightPrice != null ? '${rightPrice.toStringAsFixed(3)} DT$rightIcon' : 'N/A',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: rightColor),
                      ),
                      if (rightMed['tarif_reference'] != null)
                        Text('Réf: ${rightMed['tarif_reference']} DT',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPregnancyComparison(
    Map<String, dynamic>? leftPreg,
    Map<String, dynamic>? rightPreg,
    Map<String, dynamic> leftMed,
    Map<String, dynamic> rightMed,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤰', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Risque grossesse', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Header
          Row(
            children: [
              const SizedBox(width: 60),
              Expanded(
                child: Text(
                  (leftMed['commercial_name'] ?? leftMed['name'] ?? 'Méd 1').toString(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary.withAlpha(178)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  (rightMed['commercial_name'] ?? rightMed['name'] ?? 'Méd 2').toString(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent.withAlpha(204)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (final trimester in ['overall', 'T1', 'T2', 'T3', 'Delivery'])
            _pregnancyCompRow(
              trimester == 'overall'
                  ? 'Global'
                  : trimester == 'Delivery'
                      ? 'Accouchement'
                      : trimester,
              leftPreg?['dci_risk']?[trimester]?.toString(),
              rightPreg?['dci_risk']?[trimester]?.toString(),
            ),
        ],
      ),
    );
  }

  Widget _pregnancyCompRow(String label, String? leftRisk, String? rightRisk) {
    final leftColor = InteractionHelpers.pregnancyRiskColor(leftRisk);
    final rightColor = InteractionHelpers.pregnancyRiskColor(rightRisk);
    final leftLabel = InteractionHelpers.pregnancyRiskLabel(leftRisk);
    final rightLabel = InteractionHelpers.pregnancyRiskLabel(rightRisk);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: leftColor.withAlpha(15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(InteractionHelpers.pregnancyRiskIcon(leftRisk), size: 12, color: leftColor),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(leftLabel, style: TextStyle(fontSize: 10, color: leftColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: rightColor.withAlpha(15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(InteractionHelpers.pregnancyRiskIcon(rightRisk), size: 12, color: rightColor),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(rightLabel, style: TextStyle(fontSize: 10, color: rightColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionsComparison(
    List<dynamic> leftInter,
    List<dynamic> rightInter,
    Map<String, dynamic> leftMed,
    Map<String, dynamic> rightMed,
  ) {
    final leftName = (leftMed['commercial_name'] ?? leftMed['name'] ?? 'Méd 1').toString();
    final rightName = (rightMed['commercial_name'] ?? rightMed['name'] ?? 'Méd 2').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.compare_arrows, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Interactions avec vos traitements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(leftName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary.withAlpha(178)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    if (leftInter.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Aucune', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    else
                      ...leftInter.take(5).map((i) => _miniInteractionChip(i as Map<String, dynamic>)),
                    if (leftInter.length > 5)
                      Text('+${leftInter.length - 5} autres', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Text(rightName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent.withAlpha(204)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    if (rightInter.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Aucune', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    else
                      ...rightInter.take(5).map((i) => _miniInteractionChip(i as Map<String, dynamic>)),
                    if (rightInter.length > 5)
                      Text('+${rightInter.length - 5} autres', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInteractionChip(Map<String, dynamic> interaction) {
    final severity = interaction['severity']?.toString();
    final color = InteractionHelpers.severityColor(severity);
    final userMed = interaction['user_medication']?.toString() ?? '?';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Row(
        children: [
          Icon(InteractionHelpers.severityIcon(severity), size: 10, color: color),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              userMed,
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
