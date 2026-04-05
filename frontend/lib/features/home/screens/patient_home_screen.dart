import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

/// Home screen for patient role.
/// Loads latest measurements from backend and shows a dashboard.
class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  Map<String, dynamic>? _latestData;
  Map<String, dynamic>? _pregnancyData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authProvider);
    final patientIdStr = auth.patientId;
    if (patientIdStr == null || patientIdStr.isEmpty) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }
    final patientId = int.tryParse(patientIdStr);
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient invalide'; });
      return;
    }

    try {
      final results = await Future.wait([
        ref.read(measurementServiceProvider).getLatestMeasurements(patientId),
        ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId),
      ]);

      final measureResult = results[0];
      final pregnancyResult = results[1];

      setState(() {
        _loading = false;
        if (measureResult['success'] == true) {
          _latestData = measureResult;
        }
        if (pregnancyResult['success'] == true) {
          _pregnancyData = pregnancyResult['pregnancy'];
        }
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(auth),
                const SizedBox(height: 24),

                // Pregnancy card (if available)
                if (_pregnancyData != null) _buildPregnancyCard(),

                // Quick actions
                _buildQuickActions(),
                const SizedBox(height: 24),

                // Latest measurements
                Text('Dernières mesures', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (_loading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primary))
                else if (_error != null)
                  _buildErrorCard()
                else if (_latestData != null)
                  _buildMeasurementsGrid()
                else
                  _buildEmptyCard('Aucune mesure enregistrée', 'Commencez par ajouter vos premières mesures'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthState auth) {
    final name = auth.name ?? 'Utilisateur';
    return Row(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour 👋', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/doctors'),
          icon: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
          tooltip: 'Trouver un médecin',
        ),
      ],
    );
  }

  Widget _buildPregnancyCard() {
    final startDate = _pregnancyData!['start_date'];
    final dueDate = _pregnancyData!['due_date'];
    int? week;
    if (startDate != null) {
      final start = DateTime.tryParse(startDate);
      if (start != null) {
        week = DateTime.now().difference(start).inDays ~/ 7;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pregnant_woman, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Text('Ma grossesse', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (week != null) ...[
            Text('Semaine $week', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
          ],
          if (dueDate != null)
            Text('Date prévue: $dueDate', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_circle_outline,
            label: 'Ajouter\nune mesure',
            color: AppColors.primary,
            onTap: () => context.push('/add-measurement'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.local_hospital_outlined,
            label: 'Trouver\nun médecin',
            color: AppColors.accent,
            onTap: () => context.push('/doctors'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.notifications_outlined,
            label: 'Mes\nalertes',
            color: AppColors.warning,
            onTap: () => context.go('/alerts'),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementsGrid() {
    final data = _latestData!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MeasureCard(
              icon: Icons.monitor_weight_outlined,
              label: 'Poids',
              value: '${data['weight'] ?? '--'} kg',
              color: AppColors.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MeasureCard(
              icon: Icons.height,
              label: 'IMC',
              value: '${data['bmi'] ?? '--'}',
              color: AppColors.accent,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MeasureCard(
              icon: Icons.bloodtype_outlined,
              label: 'Glycémie',
              value: data['glycemia_informations'] != null ? '${data['glycemia_informations']['value1']} ${data['glycemia_informations']['unit'] ?? ''}' : '--',
              color: AppColors.info,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MeasureCard(
              icon: Icons.favorite_outline,
              label: 'Tension',
              value: data['blood_pressure'] != null ? '${data['blood_pressure']['value1']}/${data['blood_pressure']['value2']}' : '--',
              color: AppColors.error,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MeasureCard(
              icon: Icons.monitor_heart_outlined,
              label: 'Rythme cardiaque',
              value: data['heart_rate'] != null ? '${data['heart_rate']['value1']} bpm' : '--',
              color: AppColors.primaryDark,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MeasureCard(
              icon: Icons.thermostat_outlined,
              label: 'Température',
              value: data['body_temp'] != null ? '${data['body_temp']['value1']} °C' : '--',
              color: AppColors.warning,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 8),
          Text(_error ?? 'Erreur', style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadData, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _MeasureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MeasureCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
