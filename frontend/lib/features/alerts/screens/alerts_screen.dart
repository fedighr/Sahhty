import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/widgets/pagination_bar.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  List<dynamic> _alerts = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasNext = false;
  bool _hasPrev = false;
  static const int _pageSize = 10;

  // Filters
  String? _filterType;   // HEALTH, REMINDER, SYSTEM, DOCTOR_MESSAGE
  String? _filterLevel;  // CRITICAL, WARNING, INFO
  String? _filterStatus; // NEW, READ
  String _order = 'desc';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts({int page = 1}) async {
    setState(() { _loading = true; _error = null; });
    final userId = ref.read(authProvider).userId;
    if (userId == null || userId.isEmpty) {
      setState(() { _loading = false; _error = 'ID utilisateur non trouvé'; });
      return;
    }
    final uid = int.tryParse(userId);
    if (uid == null) {
      setState(() { _loading = false; _error = 'ID utilisateur invalide'; });
      return;
    }

    final result = await ref.read(alertServiceProvider).getAlertsByUser(
      uid,
      page: page,
      type: _filterType,
      level: _filterLevel,
      status: _filterStatus,
      order: _order,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _alerts = result['alerts'] ?? [];
        _totalCount = result['count'] ?? 0;
        _hasNext = result['next'] != null;
        _hasPrev = result['previous'] != null;
        _currentPage = page;
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  Future<void> _markAsRead(int alertId) async {
    await ref.read(alertServiceProvider).markAsRead(alertId);
    _loadAlerts(page: _currentPage);
  }

  void _resetFilters() {
    setState(() {
      _filterType = null;
      _filterLevel = null;
      _filterStatus = null;
      _order = 'desc';
    });
    _loadAlerts(page: 1);
  }

  bool get _hasActiveFilters => _filterType != null || _filterLevel != null || _filterStatus != null || _order != 'desc';

  IconData _iconForLevel(String level) {
    switch (level) {
      case 'CRITICAL': return Iconsax.warning_2;
      case 'WARNING': return Iconsax.warning_2;
      default: return Iconsax.info_circle;
    }
  }

  Color _colorForLevel(String level) {
    switch (level) {
      case 'CRITICAL': return AppColors.riskHigh;
      case 'WARNING': return AppColors.riskMedium;
      default: return AppColors.info;
    }
  }

  String _formatType(String type) {
    switch (type) {
      case 'HEALTH': return 'Santé';
      case 'REMINDER': return 'Rappel';
      case 'DOCTOR_MESSAGE': return 'Message médecin';
      case 'SYSTEM': return 'Système';
      default: return type;
    }
  }

  void _showFilterSheet() {
    final isMale = ref.read(authProvider).gender == 'M';
    final themeColor = AppColors.patientColor(isMale);
    String? tempType = _filterType;
    String? tempLevel = _filterLevel;
    String? tempStatus = _filterStatus;
    String tempOrder = _order;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Iconsax.filter, color: themeColor),
                  const SizedBox(width: 8),
                  const Text('Filtrer les alertes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setLocal(() {
                        tempType = null; tempLevel = null; tempStatus = null; tempOrder = 'desc';
                      });
                    },
                    child: Text('Réinitialiser', style: TextStyle(color: themeColor)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Type filter
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _chip('Tous', tempType == null, () => setLocal(() => tempType = null), color: themeColor),
                _chip('Santé', tempType == 'HEALTH', () => setLocal(() => tempType = 'HEALTH'), color: themeColor),
                _chip('Rappel', tempType == 'REMINDER', () => setLocal(() => tempType = 'REMINDER'), color: themeColor),
                _chip('Système', tempType == 'SYSTEM', () => setLocal(() => tempType = 'SYSTEM'), color: themeColor),
                _chip('Médecin', tempType == 'DOCTOR_MESSAGE', () => setLocal(() => tempType = 'DOCTOR_MESSAGE'), color: themeColor),
              ]),
              const SizedBox(height: 16),

              // Level filter
              const Text('Niveau', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _chip('Tous', tempLevel == null, () => setLocal(() => tempLevel = null), color: themeColor),
                _chip('Critique', tempLevel == 'CRITICAL', () => setLocal(() => tempLevel = 'CRITICAL'),
                    color: AppColors.riskHigh),
                _chip('Attention', tempLevel == 'WARNING', () => setLocal(() => tempLevel = 'WARNING'),
                    color: AppColors.riskMedium),
                _chip('Info', tempLevel == 'INFO', () => setLocal(() => tempLevel = 'INFO'),
                    color: AppColors.info),
              ]),
              const SizedBox(height: 16),

              // Status filter
              const Text('Statut', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _chip('Tous', tempStatus == null, () => setLocal(() => tempStatus = null), color: themeColor),
                _chip('Non lues', tempStatus == 'NEW', () => setLocal(() => tempStatus = 'NEW'), color: themeColor),
                _chip('Lues', tempStatus == 'READ', () => setLocal(() => tempStatus = 'READ'), color: themeColor),
              ]),
              const SizedBox(height: 16),

              // Order
              const Text('Ordre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _orderBtn('Plus récent', Iconsax.arrow_down_2, tempOrder == 'desc', themeColor,
                    () => setLocal(() => tempOrder = 'desc'))),
                const SizedBox(width: 8),
                Expanded(child: _orderBtn('Plus ancien', Iconsax.arrow_up_3, tempOrder == 'asc', themeColor,
                    () => setLocal(() => tempOrder = 'asc'))),
              ]),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterType = tempType;
                      _filterLevel = tempLevel;
                      _filterStatus = tempStatus;
                      _order = tempOrder;
                    });
                    _loadAlerts(page: 1);
                  },
                  child: const Text('Appliquer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withAlpha(30) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : Colors.transparent, width: 1.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? c : AppColors.textSecondary,
        )),
      ),
    );
  }

  Widget _orderBtn(String label, IconData icon, bool selected, Color themeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? themeColor.withAlpha(20) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? themeColor : Colors.transparent, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? themeColor : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? themeColor : AppColors.textSecondary,
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMale = ref.read(authProvider).gender == 'M';
    final themeColor = AppColors.patientColor(isMale);
    final bgGradient = isMale
        ? [AppColors.maleLight.withAlpha(180), const Color(0xFFF0F7FF), Colors.white]
        : null;
    return Scaffold(
      backgroundColor: isMale ? Colors.white : AppColors.background,
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Iconsax.filter, color: _hasActiveFilters ? themeColor : null),
                onPressed: _showFilterSheet,
                tooltip: 'Filtrer',
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBackground(showImage: false, imageOpacity: 0, gradientColors: bgGradient),
          FloatingParticles(particleCount: 10, maxOpacity: 0.1, color: isMale ? AppColors.male : null),
          Column(
            children: [
              // Active filters summary bar
              if (_hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Iconsax.filter_tick, size: 16, color: themeColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Wrap(spacing: 6, children: [
                          if (_filterType != null)
                            _activeFilterBadge(_formatType(_filterType!), () {
                              setState(() => _filterType = null);
                              _loadAlerts(page: 1);
                            }),
                          if (_filterLevel != null)
                            _activeFilterBadge(_filterLevel!, () {
                              setState(() => _filterLevel = null);
                              _loadAlerts(page: 1);
                            }),
                          if (_filterStatus != null)
                            _activeFilterBadge(_filterStatus == 'NEW' ? 'Non lues' : 'Lues', () {
                              setState(() => _filterStatus = null);
                              _loadAlerts(page: 1);
                            }),
                          if (_order != 'desc')
                            _activeFilterBadge('Plus ancien', () {
                              setState(() => _order = 'desc');
                              _loadAlerts(page: 1);
                            }),
                        ]),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text('Effacer tout', style: TextStyle(fontSize: 12, color: themeColor)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: themeColor))
                    : _error != null
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Iconsax.close_circle, size: 48, color: AppColors.error),
                            const SizedBox(height: 8),
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                            TextButton(onPressed: _loadAlerts, child: const Text('Réessayer')),
                          ]))
                        : _alerts.isEmpty
                            ? Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Iconsax.notification, size: 64, color: themeColor),
                                  const SizedBox(height: 16),
                                  const Text('Aucune alerte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _hasActiveFilters ? 'Aucun résultat pour ces filtres' : 'Tout est en ordre !',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  if (_hasActiveFilters) ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _resetFilters,
                                      icon: Icon(Iconsax.refresh_2, size: 16, color: themeColor),
                                      label: Text('Réinitialiser les filtres', style: TextStyle(color: themeColor)),
                                    ),
                                  ],
                                ]).animate().fadeIn(),
                              )
                            : RefreshIndicator(
                                onRefresh: () async { _loadAlerts(page: 1); },
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  itemCount: _alerts.length,
                                  itemBuilder: (context, i) {
                                    final alert = _alerts[i];
                                    return _buildAlertCard(alert)
                                        .animate()
                                        .fadeIn(delay: (60 * i).ms)
                                        .slideX(begin: 0.08);
                                  },
                                ),
                              ),
              ),
              if (_hasNext || _hasPrev)
                PaginationBar(
                  currentPage: _currentPage,
                  totalCount: _totalCount,
                  pageSize: _pageSize,
                  hasNext: _hasNext,
                  hasPrev: _hasPrev,
                  onPrev: () => _loadAlerts(page: _currentPage - 1),
                  onNext: () => _loadAlerts(page: _currentPage + 1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeFilterBadge(String label, VoidCallback onRemove) {
    final isMale = ref.read(authProvider).gender == 'M';
    final color = AppColors.patientColor(isMale);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close, size: 12, color: color),
        ),
      ]),
    );
  }

  Widget _buildAlertCard(dynamic alert) {
    final level = alert['level'] ?? 'INFO';
    final type = alert['type'] ?? '';
    final message = alert['message'] ?? '';
    final status = alert['status'] ?? '';
    final createdAt = alert['created_at'] ?? '';
    final id = alert['id'];
    final isRead = status == 'READ';
    final color = _colorForLevel(level);

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : color.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isRead ? const Color(0xFFE0E0E0) : color.withAlpha(64)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: !isRead && id != null ? () => _markAsRead(id) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(_iconForLevel(level), size: 22, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                          child: Text(_formatType(type), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        ),
                        const Spacer(),
                        Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        color: isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 8),
                      Text('Appuyez pour marquer comme lu',
                          style: TextStyle(fontSize: 11, color: color.withAlpha(153), fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
