import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/widgets/animated_week_counter.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class PregnancyScreen extends ConsumerStatefulWidget {
  const PregnancyScreen({super.key});

  @override
  ConsumerState<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends ConsumerState<PregnancyScreen> {
  Map<String, dynamic>? _pregnancy;
  int? _weekFromBackend;
  int? _dayFromBackend;
  bool _loading = true;
  String? _error;
  bool _noPregnancy = false;

  @override
  void initState() {
    super.initState();
    _loadPregnancy();
  }

  Future<void> _loadPregnancy() async {
    setState(() { _loading = true; _error = null; _noPregnancy = false; });
    try {
      final patientId = _getPatientId();
      if (patientId == null) {
        setState(() { _loading = false; _error = 'ID patient non trouvé. Veuillez vous reconnecter.'; });
        return;
      }

      final result = await ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result['success'] == true) {
          _pregnancy = result['pregnancy'] as Map<String, dynamic>?;
          _weekFromBackend = result['week'] as int?;
          _dayFromBackend = result['day'] as int?;
        } else {
          _noPregnancy = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Erreur de chargement: $e'; });
    }
  }

  int? _getPatientId() => int.tryParse(ref.read(authProvider).patientId ?? '');

  int get _weeks {
    if (_weekFromBackend != null) return _weekFromBackend!;
    if (_pregnancy == null || _pregnancy!['start_date'] == null) return 0;
    final start = DateTime.tryParse(_pregnancy!['start_date'].toString());
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays ~/ 7;
  }

  int get _days {
    if (_dayFromBackend != null) return _dayFromBackend! % 7;
    if (_pregnancy == null || _pregnancy!['start_date'] == null) return 0;
    final start = DateTime.tryParse(_pregnancy!['start_date'].toString());
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays % 7;
  }

  int? get _daysUntilDue {
    if (_pregnancy == null || _pregnancy!['due_date'] == null) return null;
    final due = DateTime.tryParse(_pregnancy!['due_date'].toString());
    if (due == null) return null;
    return due.difference(DateTime.now()).inDays;
  }

  double get _progress => (_weeks / 40).clamp(0.0, 1.0);

  String get _trimesterLabel {
    if (_weeks <= 12) return '1er trimestre';
    if (_weeks <= 27) return '2ème trimestre';
    return '3ème trimestre';
  }

  int get _trimesterNumber {
    if (_weeks <= 12) return 1;
    if (_weeks <= 27) return 2;
    return 3;
  }

  String get _trimesterDescription {
    if (_weeks <= 12) return 'Les organes principaux de bébé se forment. Prenez soin de vous et consultez régulièrement votre médecin.';
    if (_weeks <= 27) return 'Bébé grandit rapidement ! C\'est souvent la période la plus confortable de la grossesse.';
    return 'La dernière ligne droite ! Bébé se prépare pour la naissance. Reposez-vous bien.';
  }

  String get _babyEmoji {
    if (_weeks <= 4) return '🫘';
    if (_weeks <= 8) return '🫐';
    if (_weeks <= 12) return '🍇';
    if (_weeks <= 16) return '🍋';
    if (_weeks <= 20) return '🍌';
    if (_weeks <= 24) return '🥭';
    if (_weeks <= 28) return '🥥';
    if (_weeks <= 32) return '🍈';
    if (_weeks <= 36) return '🎃';
    return '🍉';
  }

  String get _babySizeDescription {
    if (_weeks <= 4) return 'Taille d\'une graine';
    if (_weeks <= 8) return 'Taille d\'une myrtille';
    if (_weeks <= 12) return 'Taille d\'un raisin';
    if (_weeks <= 16) return 'Taille d\'un citron';
    if (_weeks <= 20) return 'Taille d\'une banane';
    if (_weeks <= 24) return 'Taille d\'une mangue';
    if (_weeks <= 28) return 'Taille d\'une noix de coco';
    if (_weeks <= 32) return 'Taille d\'un melon';
    if (_weeks <= 36) return 'Taille d\'une citrouille';
    return 'Taille d\'une pastèque';
  }

  Color get _trimesterColor {
    if (_weeks <= 12) return AppColors.info;
    if (_weeks <= 27) return AppColors.accent;
    return AppColors.primary;
  }

  String get _trimesterImage {
    if (_weeks <= 12) return 'assets/images/baby_trimestre1.png.jpg';
    if (_weeks <= 27) return 'assets/images/baby_trimestre2.png.png';
    return 'assets/images/baby_trimestre3.png.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma grossesse')),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: true, imageOpacity: 0.08),
          const FloatingParticles(particleCount: 20, maxOpacity: 0.22),
          _loading
              ? Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Chargement de votre grossesse...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ).animate().fadeIn(),
          )
              : _error != null
              ? _buildErrorState()
              : _noPregnancy
              ? _buildNoPregnancy()
              : RefreshIndicator(
            onRefresh: _loadPregnancy,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildWeekHero().animate().fadeIn(duration: 500.ms).slideY(begin: 0.15)
                      .then()
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: -4, duration: 3500.ms, curve: Curves.easeInOut),
                  const SizedBox(height: 20),
                  _buildBabySizeCard().animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
                  const SizedBox(height: 16),
                  _buildProgressSection().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _buildDateCards().animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  _buildStatsRow().animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  _buildTrimesterInfo().animate().fadeIn(delay: 400.ms).slideX(begin: -0.05),
                  const SizedBox(height: 16),
                  if (_pregnancy?['test_date'] != null)
                    _buildTestResultCard().animate().fadeIn(delay: 450.ms),
                  SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.close_circle, size: 64, color: AppColors.error),
        ),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _loadPregnancy,
          icon: const Icon(Iconsax.refresh_2, size: 18),
          label: const Text('Réessayer'),
        ),
      ]).animate().fadeIn(),
    );
  }

  Widget _buildNoPregnancy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.heart_add, size: 80, color: AppColors.primary),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2000.ms),
            const SizedBox(height: 20),
            const Text('Aucune grossesse active', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas de grossesse en cours enregistrée.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }

  Widget _buildWeekHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withAlpha(89), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond du trimestre
            Image.asset(
              _trimesterImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark, Color(0xFFB74B5B)],
                  ),
                ),
              ),
            ),
            // Overlay sombre pour lisibilité
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(100), Colors.black.withAlpha(160)],
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(30),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2500.ms),
                        Text(_babyEmoji, style: const TextStyle(fontSize: 44))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2000.ms, curve: Curves.easeInOut),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedWeekCounter(weeks: _weeks, days: _days, size: 110),
                    const SizedBox(height: 6),
                    Text(
                      _trimesterLabel,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    if (_daysUntilDue != null && _daysUntilDue! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.clock, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_daysUntilDue!} jours restants',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBabySizeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(_babyEmoji, style: const TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1800.ms),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Taille de bébé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(_babySizeDescription, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _trimesterColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('S$_weeks', style: TextStyle(color: _trimesterColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progression', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: value, minHeight: 14, backgroundColor: AppColors.primaryLight, color: AppColors.primary),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _trimesterBadge('T1', 1),
              _trimesterBadge('T2', 2),
              _trimesterBadge('T3', 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trimesterBadge(String label, int trimester) {
    final active = _trimesterNumber == trimester;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: active ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))] : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDateCards() {
    return Row(
      children: [
        Expanded(child: _dateCard(Iconsax.calendar, 'Date début', _pregnancy?['start_date']?.toString() ?? '--', AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: _dateCard(Iconsax.calendar_1, 'Date prévue', _pregnancy?['due_date']?.toString() ?? '--', AppColors.primary)),
      ],
    );
  }

  Widget _dateCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('$_weeks', 'semaines', Iconsax.calendar, AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(_daysUntilDue != null ? '$_daysUntilDue' : '--', 'jours restants', Iconsax.clock, AppColors.warning)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('${(_weeks / 40 * 100).toInt()}', '% complété', Iconsax.tick_circle, AppColors.success)),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTrimesterInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _trimesterColor.withAlpha(15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _trimesterColor.withAlpha(38)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _trimesterColor.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Iconsax.info_circle, color: _trimesterColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_trimesterLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _trimesterColor)),
                const SizedBox(height: 4),
                Text(_trimesterDescription, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard() {
    final testDate = _pregnancy?['test_date'];
    final testResult = _pregnancy?['test_result'];
    if (testDate == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.health, size: 28, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Test de grossesse', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Date : $testDate', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (testResult != null)
                  Row(
                    children: [
                      Icon(
                        testResult == true ? Iconsax.tick_circle : Iconsax.close_circle,
                        size: 14,
                        color: testResult == true ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Résultat : ${testResult == true ? 'Positif' : 'Négatif'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: testResult == true ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}