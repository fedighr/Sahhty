import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabsFemale = ['/home', '/measurements', '/pregnancy', '/alerts', '/profile'];
  static const _tabsMale   = ['/home', '/measurements', '/alerts', '/profile'];

  int _currentIndex(BuildContext context, bool isMale) {
    final location = GoRouterState.of(context).matchedLocation;
    final tabs = isMale ? _tabsMale : _tabsFemale;
    final index = tabs.indexWhere((t) => location.startsWith(t));
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isMale = auth.gender == 'M';
    final index = _currentIndex(context, isMale);

    // Male patients use blue accent; female use pink
    final activeColor = isMale ? const Color(0xFF1565C0) : AppColors.primary;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 16, offset: const Offset(0, -4)),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Iconsax.home_2, label: 'Accueil', isSelected: index == 0, activeColor: activeColor, onTap: () => context.go('/home')),
                  _NavItem(icon: Iconsax.activity, label: 'Mesures', isSelected: index == 1, activeColor: activeColor, onTap: () => context.go('/measurements')),
                  if (!isMale)
                    _NavItem(icon: Iconsax.heart, label: 'Grossesse', isSelected: index == 2, activeColor: activeColor, onTap: () => context.go('/pregnancy')),
                  _NavItem(icon: Iconsax.notification, label: 'Alertes', isSelected: isMale ? index == 2 : index == 3, activeColor: activeColor, onTap: () => context.go('/alerts')),
                  _NavItem(icon: Iconsax.user, label: 'Profil', isSelected: isMale ? index == 3 : index == 4, activeColor: activeColor, onTap: () => context.go('/profile')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap, this.activeColor = AppColors.primary});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: widget.isSelected ? 14 : 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.activeColor.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: widget.isSelected ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Icon(widget.icon, color: widget.isSelected ? widget.activeColor : AppColors.textLight, size: 24),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: widget.isSelected ? 10 : 9,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected ? widget.activeColor : AppColors.textLight,
                ),
                child: Text(widget.label),
              ),
              // Animated dot indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 3),
                width: widget.isSelected ? 6 : 0,
                height: widget.isSelected ? 6 : 0,
                decoration: BoxDecoration(
                  color: widget.activeColor,
                  shape: BoxShape.circle,
                  boxShadow: widget.isSelected
                      ? [BoxShadow(color: widget.activeColor.withAlpha(102), blurRadius: 6)]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
