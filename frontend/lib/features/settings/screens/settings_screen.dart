import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/providers/locale_provider.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/core/providers/websocket_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deletingAccount = false;
  bool? _twoFactorEnabled; // null = unknown (not yet loaded), true/false = known
  bool _toggling2FA = false;

  int? _getPatientId() => int.tryParse(ref.read(authProvider).patientId ?? '');
  int? _getUserId() => int.tryParse(ref.read(authProvider).userId ?? '');

  Future<void> _toggle2FA() async {
    final userId = _getUserId();
    if (userId == null) return;
    setState(() => _toggling2FA = true);
    final result = await ref.read(authServiceProvider).toggle2FA(userId);
    if (!mounted) return;
    setState(() {
      _toggling2FA = false;
      if (result['success'] == true) {
        _twoFactorEnabled = result['two_factor_enabled'] as bool? ?? !(_twoFactorEnabled ?? false);
      }
    });
    _showSnackBar(
      result['success'] == true
          ? (_twoFactorEnabled == true
              ? 'Authentification à deux facteurs activée'
              : 'Authentification à deux facteurs désactivée')
          : (result['message'] ?? 'Erreur'),
      isError: result['success'] != true,
    );
  }


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
    ref.read(webSocketServiceProvider).disconnect();
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

  // ── Language ─────────────────────────────────────────────────────
  static const _languages = [
    {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
  ];

  String _currentLanguageName(String code) {
    return _languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': 'Français'},
    )['name']!;
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final current = ref.watch(localeProvider).languageCode;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Icon(Iconsax.global, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Text('Choisir la langue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._languages.map((lang) {
                    final isSelected = current == lang['code'];
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: isSelected ? AppColors.primary.withAlpha(15) : null,
                      leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                      title: Text(lang['name']!, style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      )),
                      trailing: isSelected
                          ? const Icon(Iconsax.tick_circle, color: AppColors.primary)
                          : null,
                      onTap: () async {
                        await ref.read(localeProvider.notifier).setLocale(Locale(lang['code']!));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
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
                      iconColor: Colors.grey,
                      title: 'Supprimer la grossesse',
                      subtitle: 'Supprimer les données de la grossesse actuelle',
                      isDanger: true,
                      onTap: _deletePregnancy,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
                    const SizedBox(height: 24),
                  ],

                  // ── Section: Dossier Médical ──
                  _buildSectionTitle(Iconsax.folder_open, 'Dossier médical')
                      .animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Iconsax.folder_open,
                    iconColor: Color(0xFF6C63FF),
                    title: 'Mes fichiers médicaux',
                    subtitle: 'Radios, analyses, ordonnances, résultats...',
                    onTap: () => context.push('/settings/medical-files'),
                  ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Iconsax.shield_tick,
                    iconColor: Color(0xFF43A047),
                    title: 'Médecins autorisés',
                    subtitle: 'Gérer l\'accès des médecins à votre dossier',
                    onTap: () => context.push('/settings/doctor-access'),
                  ).animate().fadeIn(delay: 380.ms).slideX(begin: 0.05),
                  const SizedBox(height: 24),

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
                  // 2FA toggle tile
                  _TwoFATile(
                    enabled: _twoFactorEnabled,
                    loading: _toggling2FA,
                    onToggle: _toggle2FA,
                  ).animate().fadeIn(delay: 720.ms).slideX(begin: 0.05),
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
                    iconColor: Colors.grey,
                    title: 'Supprimer mon compte',
                    subtitle: 'Suppression définitive de toutes vos données',
                    isDanger: true,
                    onTap: _deleteAccount,
                  ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.05),
                  const SizedBox(height: 24),

                  // ── Section: Langue ──
                  _buildSectionTitle(Iconsax.global, 'Langue & Région')
                      .animate().fadeIn(delay: 850.ms).slideX(begin: -0.05),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final currentCode = ref.watch(localeProvider).languageCode;
                    return _SettingsTile(
                      icon: Iconsax.global,
                      iconColor: AppColors.info,
                      title: 'Langue de l\'application',
                      subtitle: _currentLanguageName(currentCode),
                      onTap: _showLanguageSheet,
                    ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.05);
                  }),
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
              color: Colors.grey.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.setting_2, color: Colors.grey, size: 22),
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

// ══════════════════════════════════════════════════════════════════════
//  2FA Toggle Tile
// ══════════════════════════════════════════════════════════════════════
class _TwoFATile extends StatelessWidget {
  final bool? enabled;
  final bool loading;
  final VoidCallback onToggle;

  const _TwoFATile({
    required this.enabled,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = enabled ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(180)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.shield_security, color: Color(0xFF7C3AED), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Authentification à deux facteurs',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled == null
                      ? 'Appuyez pour activer / désactiver'
                      : isOn
                          ? 'Activée — un code sera envoyé par email à chaque connexion'
                          : 'Désactivée — connexion directe sans code',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                )
              : Switch.adaptive(
                  value: isOn,
                  onChanged: (_) => onToggle(),
                  activeColor: const Color(0xFF7C3AED),
                ),
        ],
      ),
    );
  }
}

