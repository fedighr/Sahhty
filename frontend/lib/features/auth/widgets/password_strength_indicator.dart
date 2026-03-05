// lib/features/auth/widgets/password_strength_indicator.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum PasswordStrength { none, weak, fair, good, strong }

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  static PasswordStrength _evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score <= 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _evaluate(password);

    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    final (label, color, barsFilled) = switch (strength) {
      PasswordStrength.weak => ('Faible', AppColors.error, 1),
      PasswordStrength.fair => ('Acceptable', AppColors.warning, 2),
      PasswordStrength.good => ('Bon', AppColors.accent, 3),
      PasswordStrength.strong => ('Fort', AppColors.success, 4),
      PasswordStrength.none => ('', Colors.transparent, 0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < barsFilled ? color : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Force: $label',
            key: ValueKey(strength),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
