import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class PregnancyScreen extends ConsumerStatefulWidget {
  const PregnancyScreen({super.key});

  @override
  ConsumerState<PregnancyScreen> createState() => _PregnancyScreenState();
}

class _PregnancyScreenState extends ConsumerState<PregnancyScreen> {
  Map<String, dynamic>? _pregnancy;
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
    final patientId = _getPatientId();
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _pregnancy = result['pregnancy'];
      } else {
        _noPregnancy = true;
      }
    });
  }

  int? _getPatientId() {
    return int.tryParse(ref.read(authProvider).patientId ?? '');
  }

  int? get _weeks {
    if (_pregnancy == null || _pregnancy!['start_date'] == null) return null;
    final start = DateTime.tryParse(_pregnancy!['start_date']);
    if (start == null) return null;
    return DateTime.now().difference(start).inDays ~/ 7;
  }

  int? get _days {
    if (_pregnancy == null || _pregnancy!['start_date'] == null) return null;
    final start = DateTime.tryParse(_pregnancy!['start_date']);
    if (start == null) return null;
    return DateTime.now().difference(start).inDays % 7;
  }

  int? get _daysUntilDue {
    if (_pregnancy == null || _pregnancy!['due_date'] == null) return null;
    final due = DateTime.tryParse(_pregnancy!['due_date']);
    if (due == null) return null;
    return due.difference(DateTime.now()).inDays;
  }

  double get _progress {
    final w = _weeks;
    if (w == null) return 0;
    return (w / 40).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma grossesse')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  TextButton(onPressed: _loadPregnancy, child: const Text('Réessayer')),
                ]))
              : _noPregnancy
                  ? _buildNoPregnancy()
                  : RefreshIndicator(
                      onRefresh: _loadPregnancy,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildWeekCard(),
                            const SizedBox(height: 16),
                            _buildProgressBar(),
                            const SizedBox(height: 16),
                            _buildInfoCards(),
                            const SizedBox(height: 16),
                            _buildTrimesterInfo(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildNoPregnancy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pregnant_woman, size: 80, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 20),
            const Text('Aucune grossesse active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas de grossesse en cours enregistrée.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Icon(Icons.pregnant_woman, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            _weeks != null ? 'Semaine $_weeks' : '--',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          if (_days != null && _days! > 0)
            Text('et $_days jours', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
          const SizedBox(height: 8),
          if (_daysUntilDue != null && _daysUntilDue! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$_daysUntilDue jours restants', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progression', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: AppColors.primaryLight,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('1er trim.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('2ème trim.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('3ème trim.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(child: _infoCard('Date début', _pregnancy?['start_date'] ?? '--', Icons.calendar_today, AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: _infoCard('Date prévue', _pregnancy?['due_date'] ?? '--', Icons.event, AppColors.primary)),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrimesterInfo() {
    final w = _weeks ?? 0;
    String trimester;
    String description;
    if (w <= 12) {
      trimester = '1er trimestre';
      description = 'Les organes principaux de bébé se forment. Prenez soin de vous et consultez régulièrement.';
    } else if (w <= 27) {
      trimester = '2ème trimestre';
      description = 'Bébé grandit rapidement. C\'est souvent la période la plus confortable.';
    } else {
      trimester = '3ème trimestre';
      description = 'La dernière ligne droite ! Bébé se prépare pour la naissance.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trimester, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
