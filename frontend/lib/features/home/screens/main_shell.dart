import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = ['/home', '/measurements', '/pregnancy', '/alerts', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
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
                  _NavItem(icon: Iconsax.home_2, label: 'Accueil', isSelected: index == 0, onTap: () => context.go('/home')),
                  _NavItem(icon: Iconsax.activity, label: 'Mesures', isSelected: index == 1, onTap: () => context.go('/measurements')),
                  _NavItem(icon: Iconsax.heart, label: 'Grossesse', isSelected: index == 2, onTap: () => context.go('/pregnancy')),
                  _NavItem(icon: Iconsax.notification, label: 'Alertes', isSelected: index == 3, onTap: () => context.go('/alerts')),
                  _NavItem(icon: Iconsax.user, label: 'Profil', isSelected: index == 4, onTap: () => context.go('/profile')),
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

  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

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
            color: widget.isSelected ? AppColors.primary.withAlpha(30) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: widget.isSelected ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Icon(widget.icon, color: widget.isSelected ? AppColors.primary : AppColors.textLight, size: 24),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: widget.isSelected ? 10 : 9,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected ? AppColors.primary : AppColors.textLight,
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
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: widget.isSelected
                      ? [BoxShadow(color: AppColors.primary.withAlpha(102), blurRadius: 6)]
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
