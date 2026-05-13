import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/providers/locale_provider.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String? _selected;

  static const _languages = [
    {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français', 'native': 'Bonjour !'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English', 'native': 'Hello!'},
  ];

  Future<void> _confirm() async {
    if (_selected == null) return;
    await ref.read(localeProvider.notifier).setLocale(Locale(_selected!));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(showImage: true, imageOpacity: 0.12),
          const FloatingParticles(particleCount: 20, maxOpacity: 0.25),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Header
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Iconsax.global, color: Colors.white, size: 38),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 20),
                      const Text(
                        'Choisissez votre langue',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose your language • Choisissez votre langue',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Language cards
                  Expanded(
                    child: Column(
                      children: _languages.asMap().entries.map((e) {
                        final idx = e.key;
                        final lang = e.value;
                        final isSelected = _selected == lang['code'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _LanguageCard(
                            flag: lang['flag']!,
                            name: lang['name']!,
                            native: lang['native']!,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selected = lang['code']),
                          ).animate().fadeIn(delay: (200 + idx * 100).ms).slideX(begin: 0.1),
                        );
                      }).toList(),
                    ),
                  ),
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedOpacity(
                      opacity: _selected != null ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: _selected != null ? _confirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.primary.withAlpha(80),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Continuer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Iconsax.arrow_right_3, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatefulWidget {
  final String flag;
  final String name;
  final String native;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.name,
    required this.native,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withAlpha(20)
                : Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : Colors.white.withAlpha(150),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppColors.primary.withAlpha(40)
                    : Colors.black.withAlpha(12),
                blurRadius: widget.isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.native,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isSelected
                            ? AppColors.primary.withAlpha(180)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected ? AppColors.primary : AppColors.textLight,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
