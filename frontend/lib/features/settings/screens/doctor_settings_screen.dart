import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/providers/locale_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

class DoctorSettingsScreen extends ConsumerStatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  ConsumerState<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends ConsumerState<DoctorSettingsScreen> {
  bool _deletingAccount = false;
  Map<String, dynamic>? _doctorData;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = ref.read(authProvider);
    final doctorId = int.tryParse(auth.doctorId ?? '') ?? 0;
    if (doctorId == 0) { setState(() => _loadingProfile = false); return; }
    try {
      final res = await ref.read(doctorServiceProvider).getDoctorById(doctorId);
      if (mounted) setState(() {
        if (res['success'] == true) _doctorData = res['doctor'] as Map<String, dynamic>?;
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  static const _languages = [
    {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français'},
    {'code': 'ar', 'flag': '🇸🇦', 'name': 'العربية'},
    {'code': 'en', 'flag': '🇬🇧', 'name': 'English'},
  ];

  String _currentLanguageName(String code) => _languages
      .firstWhere((l) => l['code'] == code, orElse: () => {'name': 'Français'})['name']!;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DoctorColors.warning.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Icons.logout_rounded, color: DoctorColors.warning, size: 32),
        ),
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous pourrez vous reconnecter à tout moment.',
            style: TextStyle(color: DoctorColors.textSecondary)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: DoctorColors.warning,
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

  Future<void> _deleteAccount() async {
    final userId = int.tryParse(ref.read(authProvider).userId ?? '');
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
          decoration: BoxDecoration(color: Colors.red.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        ),
        title: const Text('Supprimer le compte', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Cette action est irréversible !\nToutes vos données seront définitivement supprimées.',
          textAlign: TextAlign.center,
          style: TextStyle(color: DoctorColors.textSecondary, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    final result = await ref.read(authServiceProvider).deleteAccount(userId);
    if (!mounted) return;
    setState(() => _deletingAccount = false);

    if (result['success'] == true) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } else {
      _showSnackBar(result['message'] ?? 'Erreur lors de la suppression', isError: true);
    }
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
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
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(80), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                const Row(children: [
                  Icon(Iconsax.global, color: DoctorColors.primary, size: 22),
                  SizedBox(width: 10),
                  Text('Choisir la langue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                ..._languages.map((lang) {
                  final isSelected = current == lang['code'];
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: isSelected ? DoctorColors.primary.withAlpha(15) : null,
                    leading: Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                    title: Text(lang['name']!, style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? DoctorColors.primary : DoctorColors.textPrimary,
                    )),
                    trailing: isSelected ? const Icon(Iconsax.tick_circle, color: DoctorColors.primary) : null,
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
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Iconsax.close_circle : Iconsax.tick_circle, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red : DoctorColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: DoctorColors.background,
      appBar: AppBar(
        backgroundColor: DoctorColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => context.go('/doctor-home'),
        ),
        title: const Text('Mon profil & Paramètres', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: Stack(
        children: [
          if (_deletingAccount)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Suppression...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ]),
              ),
            ),
          CustomScrollView(
            slivers: [
              // ── Header + Profile ─────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildProfileHeader(ref.watch(authProvider)),
              ),

              // ── Content ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Compte
                      _sectionTitle(Iconsax.user, 'Compte').animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 10),
                      _Tile(
                        icon: Iconsax.user,
                        color: DoctorColors.primary,
                        title: 'Modifier mon profil',
                        subtitle: 'Nom, téléphone, ville',
                        onTap: () => context.push('/doctor/edit-profile'),
                      ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
                      const SizedBox(height: 28),

                      // Section: Dossiers médicaux
                      _sectionTitle(Iconsax.document_text, 'Dossiers médicaux').animate().fadeIn(delay: 175.ms),
                      const SizedBox(height: 10),
                      _Tile(
                        icon: Iconsax.document_like,
                        color: DoctorColors.primary,
                        title: 'Accès aux dossiers médicaux',
                        subtitle: 'Demander accès, voir les dossiers patients',
                        onTap: () => context.push('/doctor/medical-access'),
                      ).animate().fadeIn(delay: 190.ms).slideX(begin: 0.05),
                      const SizedBox(height: 28),

                      // Section: Sécurité
                      _sectionTitle(Iconsax.lock, 'Sécurité').animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 10),
                      _Tile(
                        icon: Iconsax.lock,
                        color: DoctorColors.warning,
                        title: 'Changer le mot de passe',
                        subtitle: 'Modifier votre mot de passe',
                        onTap: () => context.push('/settings/change-password'),
                      ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                      const SizedBox(height: 8),
                      _Tile(
                        icon: Iconsax.logout,
                        color: DoctorColors.warning,
                        title: 'Se déconnecter',
                        subtitle: 'Fermer votre session',
                        onTap: _logout,
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                      const SizedBox(height: 8),
                      _Tile(
                        icon: Iconsax.trash,
                        color: Colors.grey,
                        title: 'Supprimer mon compte',
                        subtitle: 'Suppression définitive',
                        isDanger: true,
                        onTap: _deleteAccount,
                      ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                      const SizedBox(height: 28),

                      // Section: Langue
                      _sectionTitle(Iconsax.global, 'Langue').animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 10),
                      Builder(builder: (context) {
                        final currentCode = ref.watch(localeProvider).languageCode;
                        return _Tile(
                          icon: Iconsax.global,
                          color: DoctorColors.accent,
                          title: 'Langue de l\'application',
                          subtitle: _currentLanguageName(currentCode),
                          onTap: _showLanguageSheet,
                        ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.05);
                      }),
                      const SizedBox(height: 32),

                      Center(child: Column(children: [
                        const Text('Sahhty', style: TextStyle(color: DoctorColors.textLight, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('v1.0.0', style: TextStyle(color: DoctorColors.textLight, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('🩺 Soigner avec excellence',
                            style: TextStyle(color: DoctorColors.primary.withAlpha(150), fontSize: 12)),
                      ])).animate().fadeIn(delay: 500.ms),
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

  Widget _buildProfileHeader(dynamic authState) {
    final name = authState.name ?? 'Médecin';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    final d = _doctorData;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Gradient top banner
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF81C784), Color(0xFFA5D6A7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withAlpha(40),
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. $name', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(authState.email ?? '', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
                      const SizedBox(height: 6),
                      if (_loadingProfile)
                        Container(width: 100, height: 16, decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(8)))
                      else if (d != null)
                        Wrap(spacing: 6, children: [
                          _headerChip(Iconsax.award, d['speciality'] ?? 'Médecin'),
                          _headerChip(Iconsax.location, d['ville'] ?? ''),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

          // Profile details
          if (_loadingProfile)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: DoctorColors.primary, strokeWidth: 2)),
            )
          else if (d != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      _statPill(Iconsax.clock, '${d['experience'] ?? 0} ans exp.'),
                      const SizedBox(width: 8),
                      _statPill(Iconsax.dollar_circle, '${d['consultation_price'] ?? '–'} TND'),
                      const SizedBox(width: 8),
                      _statPill(Iconsax.verify, 'Vérifié', color: DoctorColors.success),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 14),
                  _infoRow(Iconsax.home_2,  'Adresse', d['address'] ?? '–'),
                  if ((d['phone'] ?? '').toString().isNotEmpty)
                    _infoRow(Iconsax.call, 'Téléphone', d['phone'].toString()),
                  if ((d['bio'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: DoctorColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: Text(d['bio'], style: const TextStyle(fontSize: 13, color: DoctorColors.textSecondary, height: 1.5)),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 11),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    ]),
  );

  Widget _statPill(IconData icon, String label, {Color color = DoctorColors.primary}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 15, color: DoctorColors.primary),
      const SizedBox(width: 10),
      Text('$label :', style: const TextStyle(color: DoctorColors.textSecondary, fontSize: 12)),
      const SizedBox(width: 6),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: DoctorColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _sectionTitle(IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 20, color: DoctorColors.primary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: DoctorColors.textPrimary)),
    ]);
  }
}

// ── Reusable tile ────────────────────────────────────────────────────
class _Tile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
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
            color: widget.isDanger ? Colors.red.withAlpha(8) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isDanger ? Colors.red.withAlpha(40) : Colors.grey.withAlpha(30),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(_pressed ? 5 : 8), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: widget.color.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: widget.isDanger ? Colors.red : DoctorColors.textPrimary,
                )),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: TextStyle(
                  fontSize: 12,
                  color: widget.isDanger ? Colors.red.withAlpha(150) : DoctorColors.textSecondary,
                )),
              ],
            )),
            Icon(Iconsax.arrow_right_3,
                color: widget.isDanger ? Colors.red.withAlpha(100) : DoctorColors.textLight),
          ]),
        ),
      ),
    );
  }
}
