import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';

/// Helper class for medication interaction UI elements
class InteractionHelpers {
  InteractionHelpers._();

  /// Get color for interaction severity
  static Color severityColor(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CONTRE_INDICATION':
        return AppColors.interactionContraindication;
      case 'DECONSEILLEE':
        return AppColors.interactionDiscouraged;
      case 'PRECAUTION_EMPLOI':
        return AppColors.interactionPrecaution;
      case 'A_PRENDRE_EN_COMPTE':
        return AppColors.interactionConsideration;
      case 'NON_SIGNIFICATIVE':
        return AppColors.interactionNone;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get icon for interaction severity
  static IconData severityIcon(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CONTRE_INDICATION':
        return Iconsax.close_circle;
      case 'DECONSEILLEE':
        return Iconsax.warning_2;
      case 'PRECAUTION_EMPLOI':
        return Iconsax.warning_2;
      case 'A_PRENDRE_EN_COMPTE':
        return Iconsax.info_circle;
      case 'NON_SIGNIFICATIVE':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  /// Get human-readable label for severity
  static String severityLabel(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CONTRE_INDICATION':
        return 'Contre-indication';
      case 'DECONSEILLEE':
        return 'Déconseillée';
      case 'PRECAUTION_EMPLOI':
        return "Précaution d'emploi";
      case 'A_PRENDRE_EN_COMPTE':
        return 'À prendre en compte';
      case 'NON_SIGNIFICATIVE':
        return 'Non significative';
      default:
        return severity ?? 'Inconnu';
    }
  }

  /// Get risk level priority (higher = more dangerous)
  static int severityPriority(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CONTRE_INDICATION':
        return 5;
      case 'DECONSEILLEE':
        return 4;
      case 'PRECAUTION_EMPLOI':
        return 3;
      case 'A_PRENDRE_EN_COMPTE':
        return 2;
      case 'NON_SIGNIFICATIVE':
        return 1;
      default:
        return 0;
    }
  }

  /// Get pregnancy risk color
  static Color pregnancyRiskColor(String? risk) {
    switch (risk?.toUpperCase()) {
      case 'UNSAFE':
        return AppColors.riskHigh;
      case 'CAUTION':
        return AppColors.riskMedium;
      case 'SAFE':
        return AppColors.riskLow;
      case 'NOT_APPLICABLE':
        return AppColors.textLight;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get pregnancy risk label
  static String pregnancyRiskLabel(String? risk) {
    switch (risk?.toUpperCase()) {
      case 'UNSAFE':
        return 'Dangereux';
      case 'CAUTION':
        return 'Prudence';
      case 'SAFE':
        return 'Sûr';
      case 'NOT_APPLICABLE':
        return 'N/A';
      case 'UNKNOWN':
        return 'Inconnu';
      default:
        return risk ?? '--';
    }
  }

  /// Get pregnancy risk icon
  static IconData pregnancyRiskIcon(String? risk) {
    switch (risk?.toUpperCase()) {
      case 'UNSAFE':
        return Iconsax.warning_2;
      case 'CAUTION':
        return Iconsax.warning_2;
      case 'SAFE':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  /// Build a severity badge widget
  static Widget severityBadge(String? severity, {bool compact = false}) {
    final color = severityColor(severity);
    final icon = severityIcon(severity);
    final label = severityLabel(severity);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 3 : 5),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
