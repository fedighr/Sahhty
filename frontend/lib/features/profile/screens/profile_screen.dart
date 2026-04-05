import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _patientData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    final patientId = _getPatientId();
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(patientServiceProvider).getPatientById(patientId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _patientData = result['patient'];
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  int? _getPatientId() {
    return int.tryParse(ref.read(authProvider).patientId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  TextButton(onPressed: _loadProfile, child: const Text('Réessayer')),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar & name
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Info cards
                        if (_patientData != null) ...[
                          _buildSection('Informations personnelles', [
                            _infoRow(Icons.email_outlined, 'Email', _patientData!['email'] ?? '--'),
                            _infoRow(Icons.phone_outlined, 'Téléphone', _patientData!['phone'] ?? '--'),
                            _infoRow(Icons.cake_outlined, 'Date de naissance', '${_patientData!['birth_date'] ?? '--'}'),
                            _infoRow(Icons.person_outline, 'Âge', '${_patientData!['age'] ?? '--'} ans'),
                          ]),
                          const SizedBox(height: 16),
                          _buildSection('Informations médicales', [
                            _infoRow(Icons.height, 'Taille', '${_patientData!['height'] ?? '--'} cm'),
                            _infoRow(Icons.monitor_weight_outlined, 'Poids', '${_patientData!['weight'] ?? '--'} kg'),
                            _infoRow(Icons.bloodtype_outlined, 'Groupe sanguin', _patientData!['blood_type'] ?? 'Non renseigné'),
                            if (_patientData!['chronic_diseases'] != null && _patientData!['chronic_diseases'].toString().isNotEmpty)
                              _infoRow(Icons.medical_information_outlined, 'Maladies chroniques', _patientData!['chronic_diseases']),
                            if (_patientData!['allergies'] != null && _patientData!['allergies'].toString().isNotEmpty)
                              _infoRow(Icons.warning_amber, 'Allergies', _patientData!['allergies']),
                            if (_patientData!['family_doctor_name'] != null && _patientData!['family_doctor_name'].toString().isNotEmpty)
                              _infoRow(Icons.local_hospital_outlined, 'Médecin traitant', _patientData!['family_doctor_name']),
                          ]),

                          // Menstrual cycle if female
                          if (_patientData!['menstrual_cycle'] != null) ...[
                            const SizedBox(height: 16),
                            _buildSection('Cycle menstruel', [
                              _infoRow(Icons.loop, 'Statut', _patientData!['menstrual_cycle']['menstrual_status'] ?? '--'),
                              if (_patientData!['menstrual_cycle']['start_date'] != null)
                                _infoRow(Icons.calendar_today, 'Dernière date', '${_patientData!['menstrual_cycle']['start_date']}'),
                              if (_patientData!['menstrual_cycle']['cycle_length'] != null)
                                _infoRow(Icons.timelapse, 'Durée du cycle', '${_patientData!['menstrual_cycle']['cycle_length']} jours'),
                            ]),
                          ],
                        ],

                        const SizedBox(height: 32),

                        // Logout
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (!context.mounted) return;
                            context.go('/login');
                          },
                          icon: const Icon(Icons.logout, color: AppColors.error),
                          label: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final name = _patientData?['first_name'] != null
        ? '${_patientData!['first_name']} ${_patientData!['last_name'] ?? ''}'
        : (ref.read(authProvider).name ?? 'Utilisateur');

    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Patient', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
