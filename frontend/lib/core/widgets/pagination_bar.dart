import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';

/// A beautiful pagination bar with prev/next buttons and page indicator.
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalCount;
  final int pageSize;
  final bool hasNext;
  final bool hasPrev;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalCount,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrev,
    this.onPrev,
    this.onNext,
  });

  int get totalPages => totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          _NavButton(
            icon: Iconsax.arrow_left,
            label: 'Précédent',
            enabled: hasPrev,
            onTap: onPrev,
          ),

          // Page indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page $currentPage / $totalPages',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalCount résultat${totalCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Next button
          _NavButton(
            icon: Iconsax.arrow_right,
            label: 'Suivant',
            enabled: hasNext,
            onTap: onNext,
            isNext: true,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final bool isNext;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primary : AppColors.textLight;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryLight : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isNext
              ? [
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(width: 4),
                  Icon(icon, size: 16, color: color),
                ]
              : [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                ],
        ),
      ),
    );
  }
}
