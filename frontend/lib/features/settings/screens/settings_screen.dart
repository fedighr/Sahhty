import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deletingAccount = false;

  int? _getPatientId() => int.tryParse(ref.read(authProvider).patientId ?? '');
  int? _getUserId() => int.tryParse(ref.read(authProvider).userId ?? '');

  // ── Delete Account ───────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    final userId = _getUserId();
    if (userId == null) {
      _showSnackBar('ID utilisateur non trouvé', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 40),
        ),
        title: const Text('Supprimer le compte', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Cette action est irréversible !\n\nToutes vos données, mesures, traitements et informations de grossesse seront définitivement supprimées.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Second confirmation
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Êtes-vous absolument sûre ?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        content: const Text('Tapez sur "Confirmer" pour supprimer définitivement votre compte.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non, garder')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmer la suppression', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    final result = await ref.read(authServiceProvider).deleteAccount(userId);
    if (!mounted) return;
    setState(() => _deletingAccount = false);

    if (result['success'] == true) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
      _showSnackBar('Compte supprimé avec succès');
    } else {
      _showSnackBar(result['message'] ?? 'Erreur lors de la suppression', isError: true);
    }
  }

  // ── Logout ───────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, color: AppColors.warning, size: 32),
        ),
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous pourrez vous reconnecter à tout moment.', style: TextStyle(color: AppColors.textSecondary)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  // ── Delete Pregnancy ─────────────────────────────────────────────
  Future<void> _deletePregnancy() async {
    final patientId = _getPatientId();
    if (patientId == null) {
      _showSnackBar('ID patient non trouvé', isError: true);
      return;
    }

    // First get pregnancy to get the ID
    final pregResult = await ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId);
    if (pregResult['success'] != true || pregResult['pregnancy'] == null) {
      if (!mounted) return;
      _showSnackBar('Aucune grossesse trouvée', isError: true);
      return;
    }

    final pregnancyId = pregResult['pregnancy']['id'];
    if (pregnancyId == null) {
      if (!mounted) return;
      _showSnackBar('ID grossesse non trouvé', isError: true);
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Text('🤰', style: TextStyle(fontSize: 32)),
        ),
        title: const Text('Supprimer la grossesse ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Les données de cette grossesse seront supprimées. Cette action est irréversible.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref.read(pregnancyServiceProvider).deletePregnancy(pregnancyId);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSnackBar('Grossesse supprimée avec succès');
    } else {
      _showSnackBar(result['message'] ?? 'Erreur lors de la suppression', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Iconsax.close_circle : Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.arrow_left, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: true, imageOpacity: 0.08),
          const FloatingParticles(particleCount: 12, maxOpacity: 0.15),
          if (_deletingAccount)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Suppression du compte...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  _buildSettingsHeader(authState)
                      .animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 28),

                  // ── Section: Profil & Compte ──
                  _buildSectionTitle(Iconsax.user, 'Profil & Compte')
                      .animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Iconsax.user,
                    iconColor: AppColors.primary,
                    title: 'Modifier mon profil',
                    subtitle: 'Nom, téléphone, date de naissance',
                    onTap: () => context.push('/settings/edit-profile'),
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Iconsax.hospital,
                    iconColor: AppColors.accent,
                    title: 'Informations médicales',
                    subtitle: 'Taille, poids, groupe sanguin, allergies',
                    onTap: () => context.push('/settings/edit-medical'),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                  const SizedBox(height: 8),
                  if (authState.gender == 'F')
                    _SettingsTile(
                      icon: Iconsax.calendar,
                      iconColor: AppColors.secondary,
                      title: 'Cycle menstruel',
                      subtitle: 'Statut, dates, durée du cycle',
                      onTap: () => context.push('/settings/edit-menstrual'),
                    ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                  const SizedBox(height: 24),

                  // ── Section: Grossesse ──
                  if (authState.gender == 'F') ...[
                    _buildSectionTitle(Iconsax.heart, 'Grossesse')
                        .animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Iconsax.edit_2,
                      iconColor: AppColors.info,
                      title: 'Modifier la grossesse',
                      subtitle: 'Dates, résultat du test',
                      onTap: () => context.push('/settings/edit-pregnancy'),
                    ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Iconsax.trash,
                      iconColor: AppColors.error,
                      title: 'Supprimer la grossesse',
                      subtitle: 'Supprimer les données de la grossesse actuelle',
                      isDanger: true,
                      onTap: _deletePregnancy,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
                    const SizedBox(height: 24),
                  ],

                  // ── Section: Traitements ──
                  _buildSectionTitle(Iconsax.health, 'Traitements & Médicaments')
                      .animate().fadeIn(delay: 450.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Iconsax.health,
                    iconColor: AppColors.accent,
                    title: 'Gérer mes traitements',
                    subtitle: 'Voir, ajouter ou supprimer des traitements',
                    onTap: () => context.push('/medications'),
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05),
                  const SizedBox(height: 24),

                  // ── Section: Médecins ──
                  _buildSectionTitle(Iconsax.hospital, 'Médecins')
                      .animate().fadeIn(delay: 550.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Iconsax.hospital,
                    iconColor: AppColors.info,
                    title: 'Trouver un médecin',
                    subtitle: 'Rechercher par nom, spécialité, ville',
                    onTap: () => context.push('/doctors'),
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.05),
                  const SizedBox(height: 24),

                  // ── Section: Sécurité ──
                  _buildSectionTitle(Iconsax.lock, 'Sécurité & Confidentialité')
                      .animate().fadeIn(delay: 650.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Iconsax.lock,
                    iconColor: AppColors.warning,
                    title: 'Changer le mot de passe',
                    subtitle: 'Modifier votre mot de passe actuel',
                    onTap: () => context.push('/settings/change-password'),
                  ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.05),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Iconsax.logout,
                    iconColor: AppColors.warning,
                    title: 'Se déconnecter',
                    subtitle: 'Fermer votre session',
                    onTap: _logout,
                  ).animate().fadeIn(delay: 750.ms).slideX(begin: 0.05),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Iconsax.trash,
                    iconColor: AppColors.error,
                    title: 'Supprimer mon compte',
                    subtitle: 'Suppression définitive de toutes vos données',
                    isDanger: true,
                    onTap: _deleteAccount,
                  ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.05),
                  const SizedBox(height: 32),

                  // ── App info ──
                  Center(
                    child: Column(
                      children: [
                        Text('Sahhty', style: TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('v1.0.0', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('💕 Votre santé, notre priorité', style: TextStyle(color: AppColors.primary.withAlpha(150), fontSize: 12)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(25), AppColors.primaryLight.withAlpha(40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                (authState.name ?? 'U').isNotEmpty ? (authState.name ?? 'U')[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(authState.name ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 2),
                Text(authState.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.setting_2, color: AppColors.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Reusable Settings Tile Widget
// ══════════════════════════════════════════════════════════════════════
class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDanger
                ? AppColors.error.withAlpha(8)
                : Colors.white.withAlpha(235),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isDanger
                  ? AppColors.error.withAlpha(30)
                  : Colors.white.withAlpha(180),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_pressed ? 5 : 10),
                blurRadius: _pressed ? 4 : 12,
                offset: Offset(0, _pressed ? 1 : 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: widget.iconColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: widget.isDanger ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDanger
                            ? AppColors.error.withAlpha(150)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: widget.isDanger ? AppColors.error.withAlpha(100) : AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
