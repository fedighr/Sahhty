import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/medications/widgets/interaction_helpers.dart';

/// Bottom sheet that shows full medication details (pregnancy risk + interactions)
/// Called after `getMedicationById` API response
class MedicationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> medication;
  final Map<String, dynamic>? pregnancyData;
  final List<dynamic> interactions;
  final List<dynamic> allergyInteractions;
  final VoidCallback? onAddTreatment;

  const MedicationDetailSheet({
    super.key,
    required this.medication,
    this.pregnancyData,
    this.interactions = const [],
    this.allergyInteractions = const [],
    this.onAddTreatment,
  });

  @override
  Widget build(BuildContext context) {
    final name = (medication['commercial_name'] ?? medication['name'] ?? 'Inconnu').toString();
    final dci = (medication['dci'] ?? '').toString();
    final form = (medication['form'] ?? '').toString();
    final dosage = (medication['dosage'] ?? '').toString();
    final price = medication['public_price'];
    final category = (medication['category'] ?? '').toString();
    final pkg = (medication['package'] ?? '').toString();

    final sortedInteractions = List<dynamic>.from(interactions);
    sortedInteractions.sort((a, b) {
      final pa = InteractionHelpers.severityPriority(a['severity']?.toString());
      final pb = InteractionHelpers.severityPriority(b['severity']?.toString());
      return pb.compareTo(pa);
    });

    final hasHighRisk = sortedInteractions.any((i) =>
    InteractionHelpers.severityPriority(i['severity']?.toString()) >= 4);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withAlpha(40),
                              AppColors.primary.withAlpha(30),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Icon(Iconsax.health, size: 30, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (dci.isNotEmpty)
                              Text(
                                dci,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),

                  // ── Medication Info Chips ────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (form.isNotEmpty) _infoChip(Iconsax.health, form),
                      if (dosage.isNotEmpty) _infoChip(Iconsax.ruler, dosage),
                      if (pkg.isNotEmpty) _infoChip(Iconsax.note, pkg),
                      if (category.isNotEmpty) _infoChip(Iconsax.category, _categoryLabel(category)),
                      if (price != null && (double.tryParse(price.toString()) ?? 0) > 0)
                        _infoChip(Iconsax.tag, '${price} DT', color: AppColors.success),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ── Pregnancy Risk Section ─────────────────────
                  if (pregnancyData != null) ...[
                    _buildPregnancyRiskSection(pregnancyData!).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
                    const SizedBox(height: 16),
                  ],

                  // ── Interactions Section ───────────────────────
                  if (sortedInteractions.isNotEmpty) ...[
                    _buildInteractionsSection(sortedInteractions, hasHighRisk)
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.05),
                    const SizedBox(height: 16),
                  ],

                  // ── No interactions banner ─────────────────────
                  if (sortedInteractions.isEmpty && pregnancyData == null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success.withAlpha(51)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Iconsax.tick_circle, color: AppColors.success, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aucune interaction détectée avec vos traitements actuels',
                              style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── Allergy Warning Section ─────────────────────
                  if (allergyInteractions.isNotEmpty) ...[
                    _buildAllergySection(allergyInteractions).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── Action Button ──────────────────────────────
                  if (onAddTreatment != null) ...[
                    if (hasHighRisk) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.riskHigh.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.riskHigh.withAlpha(64)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Iconsax.warning_2, color: AppColors.riskHigh, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Attention : des interactions graves ont été détectées. Consultez votre médecin avant d\'ajouter ce traitement.',
                                style: TextStyle(fontSize: 12, color: AppColors.riskHigh, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: onAddTreatment,
                        icon: const Icon(Iconsax.add_circle, size: 20),
                        label: const Text('Ajouter comme traitement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasHighRisk ? AppColors.riskMedium : AppColors.primary,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final c = color ?? AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withAlpha(38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat.toUpperCase()) {
      case 'V':
        return 'Vital';
      case 'E':
        return 'Essentiel';
      case 'I':
        return 'Intermédiaire';
      case 'N':
        return 'Non-essentiel';
      default:
        return cat;
    }
  }

  Widget _buildPregnancyRiskSection(Map<String, dynamic> data) {
    final dciRisk = data['dci_risk'] as Map<String, dynamic>?;
    final trimesterRisk = data['trimester_risk'] as String?;
    final currentTrimester = data['current_trimester'] as String?;

    if (dciRisk == null) return const SizedBox.shrink();

    final riskColor = InteractionHelpers.pregnancyRiskColor(trimesterRisk);
    final riskIcon = InteractionHelpers.pregnancyRiskIcon(trimesterRisk);
    final riskLabel = InteractionHelpers.pregnancyRiskLabel(trimesterRisk);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: riskColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.heart_add, size: 18, color: riskColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Risque grossesse',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: riskColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Current trimester risk
          Row(
            children: [
              Icon(riskIcon, size: 20, color: riskColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$currentTrimester : $riskLabel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: riskColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // All trimesters grid
          Row(
            children: [
              _trimesterChip('T1', dciRisk['T1']?.toString()),
              const SizedBox(width: 6),
              _trimesterChip('T2', dciRisk['T2']?.toString()),
              const SizedBox(width: 6),
              _trimesterChip('T3', dciRisk['T3']?.toString()),
              const SizedBox(width: 6),
              _trimesterChip('Accou.', dciRisk['Delivery']?.toString()),
            ],
          ),
          if (dciRisk['overall'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Statut global : ${InteractionHelpers.pregnancyRiskLabel(dciRisk['overall']?.toString())}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (dciRisk['summary'] != null && dciRisk['summary'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dciRisk['summary'].toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          if (dciRisk['source_url'] != null && dciRisk['source_url'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Source : ${dciRisk['source_url']}',
              style: TextStyle(fontSize: 10, color: AppColors.primary.withAlpha(153)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _trimesterChip(String label, String? risk) {
    final color = InteractionHelpers.pregnancyRiskColor(risk);
    final riskLabel = InteractionHelpers.pregnancyRiskLabel(risk);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Icon(InteractionHelpers.pregnancyRiskIcon(risk), size: 16, color: color),
            const SizedBox(height: 2),
            Text(riskLabel, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionsSection(List<dynamic> interactions, bool hasHighRisk) {
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
                hasHighRisk ? Iconsax.warning_2 : Iconsax.chart_2,
                size: 20,
                color: hasHighRisk ? AppColors.riskHigh : AppColors.riskMedium,
              ),
              const SizedBox(width: 8),
              Text(
                'Interactions médicamenteuses (${interactions.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: hasHighRisk ? AppColors.riskHigh : AppColors.riskMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...interactions.asMap().entries.map((entry) {
            final i = entry.value as Map<String, dynamic>;
            return _buildInteractionCard(i);
          }),
        ],
      ),
    );
  }

  Widget _buildInteractionCard(Map<String, dynamic> interaction) {
    final severity = interaction['severity']?.toString();
    final color = InteractionHelpers.severityColor(severity);
    final userMed = interaction['user_medication']?.toString() ?? 'Inconnu';
    final description = interaction['description'] ?? interaction['interaction'] ?? '';
    final dci1 = interaction['dci1']?.toString() ?? '';
    final dci2 = interaction['dci2']?.toString() ?? '';

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
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllergySection(List<dynamic> allergyList) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.warning_2, size: 20, color: Color(0xFFD32F2F)),
              SizedBox(width: 8),
              Text(
                'Allergie détectée !',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...allergyList.map((a) {
            final item = a as Map<String, dynamic>;
            final allergy = item['allergy']?.toString() ?? '?';
            final rawMessage = item['message']?.toString() ?? '';
            final message = (rawMessage.isEmpty || rawMessage.toLowerCase().contains('allergic to'))
                ? 'Ce médicament contient une substance à laquelle vous êtes allergique.'
                : rawMessage;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.block, size: 18, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DCI allergène : $allergy',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F)),
                        ),
                        const SizedBox(height: 4),
                        Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

