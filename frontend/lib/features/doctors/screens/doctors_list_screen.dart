import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class DoctorsListScreen extends ConsumerStatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  ConsumerState<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends ConsumerState<DoctorsListScreen> {
  List<dynamic> _doctors = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() { _loading = true; _error = null; });
    final result = await ref.read(doctorServiceProvider).getAllDoctors();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _doctors = result['doctors'] ?? [];
        _filtered = _doctors;
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _doctors;
      } else {
        _filtered = _doctors.where((d) {
          final name = '${d['first_name']} ${d['last_name']}'.toLowerCase();
          final spec = (d['speciality'] ?? '').toString().toLowerCase();
          final ville = (d['ville'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || spec.contains(q) || ville.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un médecin'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false, imageOpacity: 0),
          const FloatingParticles(particleCount: 8, maxOpacity: 0.08),
          Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, spécialité, ville...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _searchCtrl.clear(); _filter(''); },
                      )
                    : null,
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: AppColors.error)),
                        TextButton(onPressed: _loadDoctors, child: const Text('Réessayer')),
                      ]))
                    : _filtered.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text('👨‍⚕️', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 12),
                            const Text('Aucun médecin trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ]).animate().fadeIn())
                        : RefreshIndicator(
                            onRefresh: _loadDoctors,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final d = _filtered[i];
                                return _DoctorCard(doctor: d).animate().fadeIn(delay: (60 * i).ms).slideX(begin: 0.06);
                              },
                            ),
                          ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final name = 'Dr. ${doctor['first_name'] ?? ''} ${doctor['last_name'] ?? ''}';
    final spec = doctor['speciality'] ?? 'Non spécifié';
    final ville = doctor['ville'] ?? '';
    final experience = doctor['experience'];
    final available = doctor['is_available'] == true;
    final price = doctor['consultation_price'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('👨‍⚕️', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(spec, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (ville.isNotEmpty) ...[
                      const Text('📍', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      Text(ville, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                    ],
                    if (experience != null) ...[
                      const Text('💼', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      Text('$experience ans', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: available ? AppColors.success.withAlpha(25) : AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  available ? 'Disponible' : 'Indisponible',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: available ? AppColors.success : AppColors.error),
                ),
              ),
              if (price != null) ...[
                const SizedBox(height: 4),
                Text('$price DT', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
