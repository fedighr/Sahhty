import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/data/services/vitals_sync_service.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

class SmartwatchScreen extends ConsumerStatefulWidget {
  const SmartwatchScreen({super.key});

  @override
  ConsumerState<SmartwatchScreen> createState() => _SmartwatchScreenState();
}

class _SmartwatchScreenState extends ConsumerState<SmartwatchScreen>
    with SingleTickerProviderStateMixin {
  bool _checking = true;
  bool _available = false;
  bool _permissionsGranted = false;
  bool _syncing = false;
  SyncResult? _lastResult;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkAvailability();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final hc = ref.read(healthConnectServiceProvider);
    final available = await hc.isAvailable();
    final alreadyGranted = available ? await hc.hasPermissions() : false;
    if (!mounted) return;
    setState(() {
      _checking = false;
      _available = available;
      _permissionsGranted = alreadyGranted;
    });
  }

  Future<void> _requestPermissions() async {
    final hc = ref.read(healthConnectServiceProvider);
    await hc.requestPermissions();
    final alreadyGranted = await hc.hasPermissions();
    if (!mounted) return;
    setState(() => _permissionsGranted = alreadyGranted);
    if (!alreadyGranted) {
      _showSnack(
        'Permissions refusées. Activez-les dans les paramètres Health Connect.',
        isError: true,
      );
    }
  }

  Future<void> _syncNow() async {
    final patientIdStr = ref.read(authProvider).patientId;
    final patientId = int.tryParse(patientIdStr ?? '');
    if (patientId == null) {
      _showSnack('ID patient non trouvé', isError: true);
      return;
    }

    setState(() {
      _syncing = true;
      _lastResult = null;
    });

    final result = await ref.read(vitalsSyncServiceProvider).syncNow(patientId: patientId);

    if (!mounted) return;
    setState(() {
      _syncing = false;
      _lastResult = result;
    });

    if (result.measurements.isNotEmpty) {
      // Measurements are returned by the backend — no second call needed
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Montre connectée'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Hero illustration
              _buildHeroCard(),
              const SizedBox(height: 24),

              if (_checking)
                const Center(child: CircularProgressIndicator())
              else if (!_available)
                _buildNotAvailableCard()
              else ...[
                if (!_permissionsGranted) _buildPermissionCard(),
                if (_permissionsGranted) ...[
                  _buildSyncButton(),
                  const SizedBox(height: 16),
                  if (_lastResult != null) _buildResultCard(_lastResult!),
                ],
                const SizedBox(height: 24),
                _buildInfoCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + _pulseController.value * 0.08,
                child: child,
              );
            },
            child: const Icon(Icons.watch, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Health Connect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Synchronisez votre rythme cardiaque depuis votre montre connectée',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }

  Widget _buildNotAvailableCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withAlpha(100)),
      ),
      child: Column(
        children: [
          const Icon(Icons.watch_off, size: 48, color: AppColors.warning),
          const SizedBox(height: 12),
          const Text(
            'Health Connect non disponible',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Installez Health Connect depuis le Google Play Store et assurez-vous que votre montre y est connectée.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.health_and_safety, size: 48, color: AppColors.accent),
          const SizedBox(height: 12),
          const Text(
            'Autoriser l\'accès aux données',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sahhty a besoin d\'accéder à Health Connect pour lire votre rythme cardiaque.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _requestPermissions,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Autoriser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _syncing ? null : _syncNow,
        icon: _syncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.sync),
        label: Text(_syncing ? 'Synchronisation...' : 'Synchroniser maintenant'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildResultCard(SyncResult result) {
    final isSuccess = result.success && result.sent > 0;
    final isEmpty = result.sent == 0 && result.errors.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSuccess
              ? AppColors.success.withAlpha(100)
              : isEmpty
                  ? AppColors.warning.withAlpha(100)
                  : AppColors.error.withAlpha(100),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : isEmpty ? Icons.info_outline : Icons.error_outline,
            color: isSuccess ? AppColors.success : isEmpty ? AppColors.warning : AppColors.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            isSuccess
                ? '${result.sent} mesure(s) envoyée(s)'
                : isEmpty
                    ? 'Aucune donnée disponible'
                    : 'Erreur de synchronisation',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (result.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                result.errors.first,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          // Display measurements returned by the backend
          if (result.measurements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Mesures enregistrées', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...result.measurements.map((m) => _buildMeasurementTile(m)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildMeasurementTile(Map<String, dynamic> m) {
    final type = m['type']?.toString() ?? '';
    final value1 = m['value1']?.toString() ?? '';
    final value2 = m['value2']?.toString();
    final unit = m['unit']?.toString() ?? '';

    final icons = {
      'HEART_RATE': Icons.favorite,
      'TEMPERATURE': Icons.thermostat,
      'BLOOD_PRESSURE': Icons.speed,
      'OXYGEN': Icons.air,
      'WEIGHT': Icons.monitor_weight,
      'GLYCEMIA': Icons.bloodtype,
    };

    final labels = {
      'HEART_RATE': 'Rythme cardiaque',
      'TEMPERATURE': 'Température',
      'BLOOD_PRESSURE': 'Tension artérielle',
      'OXYGEN': 'Oxygène',
      'WEIGHT': 'Poids',
      'GLYCEMIA': 'Glycémie',
    };

    final unitLabels = {
      'BPM': 'bpm',
      'C': '°C',
      'MMHG': 'mmHg',
      'KG': 'kg',
      'G_L': 'g/L',
    };

    String displayValue = value1;
    if (value2 != null && value2.isNotEmpty && value2 != 'null') {
      displayValue = '$value1 / $value2';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icons[type] ?? Icons.monitor_heart, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              labels[type] ?? type,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '$displayValue ${unitLabels[unit] ?? unit}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Comment ça marche ?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.watch, 'Votre montre mesure automatiquement votre rythme cardiaque'),
          _infoRow(Icons.sync_alt, 'Le dernier rythme cardiaque est récupéré depuis Health Connect'),
          _infoRow(Icons.cloud_upload_outlined, 'Appuyez sur Synchroniser pour envoyer la dernière mesure'),
          _infoRow(Icons.shield_outlined, 'Vos données restent sécurisées et privées'),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
