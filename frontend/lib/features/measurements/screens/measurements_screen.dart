import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/widgets/pagination_bar.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

/// Lists all measurements and allows viewing history.
class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _FilterType {
  final String? value;
  final String label;
  final IconData icon;
  final Color color;
  const _FilterType(this.value, this.label, this.icon, this.color);
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  List<dynamic> _measurements = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasNext = false;
  bool _hasPrev = false;
  static const int _pageSize = 10;
  String? _selectedType;

  static const List<_FilterType> _filters = [
    _FilterType(null, 'Tous', Iconsax.category, AppColors.primary),
    _FilterType('WEIGHT', 'Poids', Iconsax.weight, Color(0xFF8B5CF6)),
    _FilterType('BLOOD_PRESSURE', 'Tension', Iconsax.heart, Color(0xFFEF4444)),
    _FilterType('GLYCEMIA', 'Glycémie', Iconsax.drop, Color(0xFF3B82F6)),
    _FilterType('TEMPERATURE', 'Temp.', Iconsax.health, Color(0xFFF59E0B)),
    _FilterType('HEART_RATE', 'Rythme', Iconsax.activity, Color(0xFFEC4899)),
    _FilterType('OXYGEN', 'Oxygène', Iconsax.wind_2, Color(0xFF06B6D4)),
  ];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements({int page = 1, String? type}) async {
    setState(() { _loading = true; _error = null; });
    final patientId = _getPatientId();
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(measurementServiceProvider).getPatientMeasurements(
      patientId,
      page: page,
      typeFilter: type ?? _selectedType,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _measurements = result['measurements'] ?? [];
        _totalCount = result['count'] ?? 0;
        _hasNext = result['next'] != null;
        _hasPrev = result['previous'] != null;
        _currentPage = page;
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  int? _getPatientId() => int.tryParse(ref.read(authProvider).patientId ?? '');

  IconData _iconForType(String type) {
    for (final f in _filters) {
      if (f.value == type) return f.icon;
    }
    return Iconsax.chart_2;
  }

  String _formatType(String type) {
    switch (type) {
      case 'WEIGHT': return 'Poids';
      case 'BLOOD_PRESSURE': return 'Tension artérielle';
      case 'GLYCEMIA': return 'Glycémie';
      case 'TEMPERATURE': return 'Température';
      case 'HEART_RATE': return 'Rythme cardiaque';
      case 'OXYGEN': return 'Oxygène';
      default: return type;
    }
  }

  Color _colorForType(String type) {
    for (final f in _filters) {
      if (f.value == type) return f.color;
    }
    return AppColors.textSecondary;
  }

  void _onFilterTap(_FilterType filter) {
    if (_selectedType == filter.value) return;
    setState(() { _selectedType = filter.value; });
    _loadMeasurements(page: 1, type: filter.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes mesures'),
        actions: [
          IconButton(
            onPressed: () async {
              await context.push('/add-measurement');
              _loadMeasurements(page: 1);
            },
            icon: const Icon(Iconsax.add_circle, size: 26, color: AppColors.primary),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false, imageOpacity: 0),
          const FloatingParticles(particleCount: 10, maxOpacity: 0.1),
          Column(
            children: [
              // ─── Filter bar ───────────────────────────────────────
              _buildFilterBar(),
              // ─── Content ─────────────────────────────────────────
              Expanded(child: _buildContent()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final isSelected = _selectedType == f.value;
          return GestureDetector(
            onTap: () => _onFilterTap(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? f.color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? f.color.withAlpha(80) : Colors.black.withAlpha(15),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 3),
                  )
                ],
                border: Border.all(
                  color: isSelected ? f.color : Colors.grey.withAlpha(40),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.icon, size: 20, color: isSelected ? Colors.white : f.color),
                  const SizedBox(height: 4),
                  Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate(target: isSelected ? 1 : 0).scaleXY(begin: 1, end: 1.05),
          );
        },
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Iconsax.close_circle, size: 48, color: AppColors.error),
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: AppColors.error)),
        TextButton(onPressed: _loadMeasurements, child: const Text('Réessayer')),
      ]));
    }
    if (_measurements.isEmpty) {
      final f = _filters.firstWhere((f) => f.value == _selectedType, orElse: () => _filters[0]);
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: f.color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(f.icon, size: 48, color: f.color),
        ),
        const SizedBox(height: 16),
        Text(
          _selectedType == null ? 'Aucune mesure' : 'Aucune mesure de type « ${_formatType(_selectedType!)} »',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text('Ajoutez votre première mesure', style: TextStyle(color: AppColors.textSecondary)),
      ]).animate().fadeIn());
    }

    return RefreshIndicator(
      onRefresh: () async => _loadMeasurements(page: 1),
      child: Column(
        children: [
          // Count badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_totalCount résultat${_totalCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: _measurements.length,
              itemBuilder: (context, i) => _buildMeasurementCard(_measurements[i], i),
            ),
          ),
          if (_hasNext || _hasPrev)
            PaginationBar(
              currentPage: _currentPage,
              totalCount: _totalCount,
              pageSize: _pageSize,
              hasNext: _hasNext,
              hasPrev: _hasPrev,
              onPrev: () => _loadMeasurements(page: _currentPage - 1),
              onNext: () => _loadMeasurements(page: _currentPage + 1),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(dynamic m, int index) {
    final type = m['type'] ?? '';
    final value1 = m['value1'];
    final value2 = m['value2'];
    final unit = m['unit'] ?? '';
    final date = m['measurement_date'] ?? '';
    final ctxField = m['context'] ?? '';
    final color = _colorForType(type);

    String displayValue = '$value1';
    if (value2 != null) displayValue += '/$value2';
    displayValue += ' $unit';

    String dateStr = '';
    if (date.isNotEmpty) {
      final dt = DateTime.tryParse(date);
      if (dt != null) {
        dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Colored left accent
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: color)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Icon(_iconForType(type), size: 24, color: color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatType(type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 3),
                        Text(displayValue, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
                        if (ctxField.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(Iconsax.info_circle, size: 11, color: AppColors.textLight),
                            const SizedBox(width: 3),
                            Text(ctxField, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(dateStr, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.06);
  }
}
