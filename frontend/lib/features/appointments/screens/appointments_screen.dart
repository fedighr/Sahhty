import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with TickerProviderStateMixin {
  List<dynamic> _appointments = [];
  bool _loading = true;
  String? _error;
  late AnimationController _headerController;
  String _statusFilter = 'Tous';

  static const _statusFilters = ['Tous', 'En attente', 'Confirmé', 'Annulé'];

  List<dynamic> get _filteredAppointments {
    if (_statusFilter == 'Tous') return _appointments;
    final map = {'En attente': 'PENDING', 'Confirmé': 'CONFIRMED', 'Annulé': 'CANCELLED'};
    final key = map[_statusFilter];
    return _appointments.where((a) => a['status'] == key).toList();
  }

  int _countByStatus(String status) {
    final map = {'PENDING': 0, 'CONFIRMED': 0, 'CANCELLED': 0};
    for (final a in _appointments) {
      final s = a['status'] ?? '';
      if (map.containsKey(s)) map[s] = (map[s] ?? 0) + 1;
    }
    return map[status] ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _headerController.forward();
    _loadAppointments();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() { _loading = true; _error = null; });
    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }
    final result = await ref.read(appointmentServiceProvider).getPatientTodayAppointments(patientId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _appointments = result['appointments'] ?? [];
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.calendar_remove, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              const Text('Annuler le rendez-vous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Êtes-vous sûr de vouloir annuler ce rendez-vous ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Non, garder'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Oui, annuler'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    final result = await ref.read(appointmentServiceProvider).cancelAppointment(appointmentId, 'PATIENT');
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Rendez-vous annulé'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ));
      _loadAppointments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Erreur'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false, imageOpacity: 0),
          const FloatingParticles(particleCount: 8, maxOpacity: 0.06),
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (!_loading && _error == null && _appointments.isNotEmpty)
                SliverToBoxAdapter(child: _buildStatsAndFilter()),
              SliverToBoxAdapter(
                child: _loading
                    ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                    : _error != null
                        ? _buildError()
                        : _appointments.isEmpty
                            ? _buildEmpty()
                            : _filteredAppointments.isEmpty
                                ? _buildFilterEmpty()
                                : _buildAppointmentsList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          // Mini stats row
          Row(
            children: [
              _statChip(Iconsax.clock, _countByStatus('PENDING'), 'En attente', AppColors.warning),
              const SizedBox(width: 8),
              _statChip(Iconsax.tick_circle, _countByStatus('CONFIRMED'), 'Confirmés', AppColors.success),
              const SizedBox(width: 8),
              _statChip(Iconsax.close_circle, _countByStatus('CANCELLED'), 'Annulés', AppColors.error),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              itemBuilder: (_, i) {
                final f = _statusFilters[i];
                final selected = _statusFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _statusFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
                      boxShadow: selected ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 8)] : [],
                    ),
                    child: Text(f, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    )),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: color), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.calendar, size: 40, color: AppColors.primary),
          ).animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text('Aucun rendez-vous "$_statusFilter"',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Iconsax.add, color: Colors.white, size: 20),
            onPressed: () async {
              await context.push('/doctors');
              _loadAppointments();
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8FA3), Color(0xFFFFB3C1), Color(0xFFFCE4EC)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(80),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Iconsax.calendar_2, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mes rendez-vous',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('${_appointments.length} rendez-vous aujourd\'hui',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ).animate(controller: _headerController).fadeIn().slideX(begin: -0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.close_circle, size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Iconsax.refresh_2, size: 18),
            label: const Text('Réessayer'),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withAlpha(30), AppColors.secondary.withAlpha(50)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.calendar, size: 56, color: AppColors.primary),
          ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text('Aucun rendez-vous aujourd\'hui',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Prenez rendez-vous avec un médecin pour un suivi personnalisé',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                await context.push('/doctors');
                _loadAppointments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Iconsax.add_circle, color: Colors.white, size: 20),
              label: const Text('Prendre un rendez-vous',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildAppointmentsList() {
    final list = _filteredAppointments;
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          children: List.generate(list.length, (i) {
            final appt = list[i];
            return _AppointmentCard(
              appointment: appt,
              index: i,
              isLast: i == list.length - 1,
              onCancel: () => _cancelAppointment(appt['id']),
            ).animate().fadeIn(delay: (80 * i).ms).slideY(begin: 0.08);
          }),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final int index;
  final bool isLast;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.index,
    required this.isLast,
    required this.onCancel,
  });

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.appointment['status'] ?? '') {
      case 'CONFIRMED': return AppColors.success;
      case 'PENDING': return AppColors.warning;
      case 'CANCELLED': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (widget.appointment['status'] ?? '') {
      case 'CONFIRMED': return Iconsax.tick_circle;
      case 'PENDING': return Iconsax.clock;
      case 'CANCELLED': return Iconsax.close_circle;
      default: return Iconsax.info_circle;
    }
  }

  String get _statusLabel {
    switch (widget.appointment['status'] ?? '') {
      case 'CONFIRMED': return 'Confirmé';
      case 'PENDING': return 'En attente';
      case 'CANCELLED': return 'Annulé';
      default: return widget.appointment['status'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    final dateStr = appt['appointment_date'] ?? '';
    DateTime? date;
    try { date = DateTime.parse(dateStr); } catch (_) {}

    final doctorObj = appt['doctor'];
    String doctorName = 'Médecin inconnu';
    String doctorSpec = '';
    if (doctorObj is Map) {
      final userObj = doctorObj['user'];
      if (userObj is Map) {
        doctorName = 'Dr. ${userObj['first_name'] ?? ''} ${userObj['last_name'] ?? ''}';
      }
      final specObj = doctorObj['speciality'];
      doctorSpec = specObj is Map ? (specObj['name'] ?? '') : (specObj?.toString() ?? '');
    }

    final reason = appt['reason'];
    final status = appt['status'] ?? '';
    final canCancel = status == 'PENDING' || status == 'CONFIRMED';

    // Color accent per index
    final accentColors = [
      const Color(0xFFFF8FA3),
      const Color(0xFFFFB74D),
      const Color(0xFF80CBC4),
      const Color(0xFFCE93D8),
      const Color(0xFF90CAF9),
    ];
    final accentColor = accentColors[widget.index % accentColors.length];

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: accentColor.withAlpha(30), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              // Colored top accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentColor, accentColor.withAlpha(120)]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Doctor avatar
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor.withAlpha(50), accentColor.withAlpha(30)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Iconsax.user, size: 26, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              if (doctorSpec.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(doctorSpec,
                                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _statusColor.withAlpha(60), width: 1),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_statusIcon, size: 13, color: _statusColor),
                            const SizedBox(width: 4),
                            Text(_statusLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Date & time strip
                    if (date != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.calendar_1, size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Spacer(),
                            Container(width: 1, height: 16, color: AppColors.textLight),
                            const Spacer(),
                            Icon(Iconsax.clock, size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    // Expandable detail
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _expanded ? Column(children: [
                        if (reason != null && reason.toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Iconsax.note_text, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(reason.toString(),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                        if (canCancel) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: widget.onCancel,
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColors.error.withAlpha(15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                icon: const Icon(Iconsax.calendar_remove, size: 16, color: AppColors.error),
                                label: const Text('Annuler le RDV',
                                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ]) : const SizedBox.shrink(),
                    ),
                    // Expand indicator
                    Center(
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(Iconsax.arrow_down, size: 16, color: AppColors.textLight),
                      ),
                    ),
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
