import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/core/widgets/pagination_bar.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

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
  String _order = 'desc'; // 'asc' or 'desc'

  // Pagination (server-side for patient)
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasNext = false;
  bool _hasPrev = false;
  static const int _pageSize = 5;

  // Stats indépendants du filtre actif (patient seulement)
  Map<String, int> _globalStats = {'PENDING': 0, 'CONFIRMED': 0, 'CANCELLED': 0, 'COMPLETED': 0};

  // For doctor, client-side pagination remains
  static const _statusFilters = ['Tous', 'En attente', 'Confirmé', 'Terminé'];

  // Only used for doctor (client-side)
  List<dynamic> get _filteredAppointments {
    if (ref.read(authProvider).role != 'D') return _appointments;
    if (_statusFilter == 'Tous') return _appointments;
    final map = {'En attente': 'PENDING', 'Confirmé': 'CONFIRMED', 'Terminé': 'COMPLETED'};
    final key = map[_statusFilter];
    return _appointments.where((a) => a['status'] == key).toList();
  }

  List<dynamic> get _pagedAppointments {
    final isDoctor = ref.read(authProvider).role == 'D';
    if (!isDoctor) return _appointments; // server already paginated
    final list = _filteredAppointments;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= list.length) return [];
    final end = (start + _pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _totalPages {
    final isDoctor = ref.read(authProvider).role == 'D';
    if (!isDoctor) return (_totalCount / _pageSize).ceil().clamp(1, 999);
    return (_filteredAppointments.length / _pageSize).ceil().clamp(1, 999);
  }

  int _countByStatus(String status) {
    final isDoctor = ref.read(authProvider).role == 'D';
    if (isDoctor) {
      // For doctor, all appointments are loaded client-side
      final map = {'PENDING': 0, 'CONFIRMED': 0, 'CANCELLED': 0, 'COMPLETED': 0};
      for (final a in _appointments) {
        final s = a['status'] ?? '';
        if (map.containsKey(s)) map[s] = (map[s] ?? 0) + 1;
      }
      return map[status] ?? 0;
    }
    // For patient, use global stats loaded without filter
    return _globalStats[status] ?? 0;
  }

  Future<void> _loadGlobalStats() async {
    final auth = ref.read(authProvider);
    if (auth.role == 'D') return; // doctor loads all at once
    final patientId = int.tryParse(auth.patientId ?? '');
    if (patientId == null) return;
    // Fetch all statuses with a large page to count
    final statuses = ['PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'];
    final counts = <String, int>{};
    for (final s in statuses) {
      final r = await ref.read(appointmentServiceProvider).getPatientAllAppointments(
        patientId, status: s, page: 1,
      );
      counts[s] = (r['count'] as int?) ?? 0;
    }
    if (!mounted) return;
    setState(() { _globalStats = counts; });
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _headerController.forward();
    _loadGlobalStats();
    _loadAppointments();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments({bool resetPage = true}) async {
    setState(() { _loading = true; _error = null; if (resetPage) _currentPage = 1; });
    final auth = ref.read(authProvider);
    final isDoctor = auth.role == 'D';
    if (isDoctor) {
      final doctorId = int.tryParse(auth.doctorId ?? '');
      if (doctorId == null) {
        setState(() { _loading = false; _error = 'ID médecin non trouvé'; });
        return;
      }
      final result = await ref.read(appointmentServiceProvider).getDoctorAllAppointments(doctorId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result['success'] == true) {
          _appointments = result['appointments'] ?? [];
        } else {
          _error = result['message'] ?? 'Erreur';
        }
      });
    } else {
      final patientId = int.tryParse(auth.patientId ?? '');
      if (patientId == null) {
        setState(() { _loading = false; _error = 'ID patient non trouvé'; });
        return;
      }
      final statusParam = _statusFilter == 'Tous' ? null : _statusFilterToApi(_statusFilter);
      final result = await ref.read(appointmentServiceProvider).getPatientAllAppointments(
        patientId,
        status: statusParam,
        order: _order,
        page: _currentPage,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result['success'] == true) {
          _appointments = result['appointments'] ?? [];
          _totalCount = result['count'] ?? 0;
          _hasNext = result['next'] != null;
          _hasPrev = result['previous'] != null;
        } else {
          _error = result['message'] ?? 'Erreur';
        }
      });
    }
  }

  String? _statusFilterToApi(String label) {
    const map = {'En attente': 'PENDING', 'Confirmé': 'CONFIRMED', 'Terminé': 'COMPLETED'};
    return map[label];
  }

  Future<void> _confirmAppointment(int appointmentId) async {
    final result = await ref.read(appointmentServiceProvider).confirmAppointment(appointmentId);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Rendez-vous confirmé'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ));
      _loadAppointments();
      _loadGlobalStats();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Erreur'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ));
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    final isDoctor = ref.read(authProvider).role == 'D';
    final isMale = ref.read(authProvider).gender == 'M';
    final primary = isDoctor ? DoctorColors.primary : AppColors.patientColor(isMale);
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
                  color: Colors.red.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.calendar_remove, size: 32, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text('Annuler le rendez-vous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Êtes-vous sûr de vouloir annuler ce rendez-vous ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Non, garder'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
    final result = await ref.read(appointmentServiceProvider).cancelAppointment(appointmentId, isDoctor ? 'DOCTOR' : 'PATIENT');
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
      _loadGlobalStats();
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
    final isDoctor = ref.read(authProvider).role == 'D';
    final isMale = ref.read(authProvider).gender == 'M';
    final patientColor = AppColors.patientColor(isMale);
    return Scaffold(
      backgroundColor: isDoctor ? DoctorColors.background : AppColors.background,
      body: Stack(
        children: [
          if (!isDoctor) ...[
            AnimatedBackground(showImage: false, imageOpacity: 0, isMale: isMale),
            const FloatingParticles(particleCount: 8, maxOpacity: 0.06),
          ] else
            _buildDoctorBackground(),
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (!_loading && _error == null && (isDoctor ? _appointments.isNotEmpty : true))
                SliverToBoxAdapter(child: _buildStatsAndFilter()),
              SliverToBoxAdapter(
                child: _loading
                    ? SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: isDoctor ? DoctorColors.primary : patientColor)))
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

  Widget _buildDoctorBackground() {
    return Stack(
      children: [
        Container(color: DoctorColors.background),
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [DoctorColors.primary.withAlpha(30), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [DoctorColors.accent.withAlpha(25), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsAndFilter() {
    final isDoctor = ref.read(authProvider).role == 'D';
    final isMale = ref.read(authProvider).gender == 'M';
    final primary = isDoctor ? DoctorColors.primary : AppColors.patientColor(isMale);
    final pendingColor = isDoctor ? DoctorColors.warning : AppColors.warning;
    final successColor = isDoctor ? DoctorColors.success : AppColors.success;
    final errorColor = isDoctor ? DoctorColors.error : AppColors.error;
    final textSec = isDoctor ? DoctorColors.textSecondary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini stats row
          Row(
            children: [
              _statChip(Iconsax.clock, _countByStatus('PENDING'), 'En attente', pendingColor),
              const SizedBox(width: 6),
              _statChip(Iconsax.tick_circle, _countByStatus('CONFIRMED'), 'Confirmés', successColor),
              const SizedBox(width: 6),
              _statChip(Iconsax.medal_star, _countByStatus('COMPLETED'), 'Terminés', primary),
              const SizedBox(width: 6),
              _statChip(Iconsax.close_circle, _countByStatus('CANCELLED'), 'Annulés', errorColor),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          // Filter chips + order toggle row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    itemBuilder: (_, i) {
                      final f = _statusFilters[i];
                      final selected = _statusFilter == f;
                      return GestureDetector(
                        onTap: () {
                          setState(() { _statusFilter = f; _currentPage = 1; });
                          _loadAppointments(resetPage: true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? primary : const Color(0xFFE0E0E0)),
                            boxShadow: selected ? [BoxShadow(color: primary.withAlpha(60), blurRadius: 8)] : [],
                          ),
                          child: Text(f, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : textSec,
                          )),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Order toggle (patient only — server-side)
              if (!isDoctor)
                GestureDetector(
                  onTap: () {
                    setState(() => _order = _order == 'desc' ? 'asc' : 'desc');
                    _loadAppointments(resetPage: true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: primary.withAlpha(60)),
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: _order == 'desc' ? 0 : 0.5,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Iconsax.arrow_down, size: 18, color: primary),
                      ),
                    ),
                  ),
                ),
            ],
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
    final isDoctor = ref.read(authProvider).role == 'D';
    final isMale = ref.read(authProvider).gender == 'M';
    final primary = isDoctor ? DoctorColors.primary : AppColors.patientColor(isMale);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.calendar, size: 40, color: primary),
          ).animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text('Aucun rendez-vous "$_statusFilter"',
            style: TextStyle(color: isDoctor ? DoctorColors.textSecondary : AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildSliverAppBar() {
    final isDoctor = ref.read(authProvider).role == 'D';
    final isMale = ref.read(authProvider).gender == 'M';
    final primary = isDoctor ? DoctorColors.primary : AppColors.patientColor(isMale);
    final primaryDark = isDoctor ? DoctorColors.primaryDark : AppColors.patientDarkColor(isMale);
    final gradientColors = isDoctor
        ? [DoctorColors.primaryDark, DoctorColors.primary, DoctorColors.accent]
        : [AppColors.patientColor(isMale), AppColors.patientDarkColor(isMale)];

    return SliverAppBar(
      expandedHeight: 160,
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
          icon: Icon(Iconsax.arrow_left, color: primaryDark, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                final role = ref.read(authProvider).role;
                context.go(role == 'D' ? '/doctor-home' : '/home');
              }
            },
        ),
      ),
      actions: [
        if (!isDoctor)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary,
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
        if (isDoctor)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Iconsax.refresh_2, color: primary, size: 20),
              onPressed: _loadAppointments,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles for doctor
              if (isDoctor) ...[
                Positioned(
                  top: -30, right: -30,
                  child: Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(15),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, left: -20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(10),
                    ),
                  ),
                ),
              ],
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(80),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withAlpha(100), width: 1),
                            ),
                            child: Icon(
                              isDoctor ? Iconsax.people : Iconsax.calendar_2,
                              color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isDoctor ? 'Mes Patients' : 'Mes Rendez-vous',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('${_appointments.length} rendez-vous',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate(controller: _headerController).fadeIn().slideX(begin: -0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final isDoctor = ref.read(authProvider).role == 'D';
    final primary = isDoctor ? DoctorColors.primary : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.close_circle, size: 40, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Iconsax.refresh_2, size: 18),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildEmpty() {
    final isDoctor = ref.read(authProvider).role == 'D';
    final primary = isDoctor ? DoctorColors.primary : AppColors.primary;
    final secondary = isDoctor ? DoctorColors.accent : AppColors.secondary;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withAlpha(30), secondary.withAlpha(50)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(isDoctor ? Iconsax.people : Iconsax.calendar, size: 56, color: primary),
          ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(isDoctor ? 'Aucun rendez-vous' : 'Aucun rendez-vous pour le moment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: isDoctor ? DoctorColors.textPrimary : AppColors.textPrimary),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            isDoctor
              ? 'Vos rendez-vous patients apparaîtront ici'
              : 'Prenez rendez-vous avec un médecin pour un suivi personnalisé',
            style: TextStyle(
              color: isDoctor ? DoctorColors.textSecondary : AppColors.textSecondary,
              fontSize: 14),
            textAlign: TextAlign.center),
          const SizedBox(height: 28),
          if (!isDoctor)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primary, primary.withAlpha(180)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: primary.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
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
    final list = _pagedAppointments;
    final isDoctor = ref.read(authProvider).role == 'D';
    final primary = isDoctor ? DoctorColors.primary : AppColors.primary;

    // For patient: server handles pagination, _hasNext/_hasPrev tell us the state
    // For doctor: client-side pagination
    final showPagination = isDoctor
        ? _filteredAppointments.length > _pageSize
        : (_hasNext || _hasPrev);

    return RefreshIndicator(
      onRefresh: () => _loadAppointments(resetPage: true),
      color: primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            ...List.generate(list.length, (i) {
              final appt = list[i];
              return _AppointmentCard(
                appointment: appt,
                index: i,
                isLast: i == list.length - 1,
                onCancel: () => _cancelAppointment(appt['id']),
                onConfirm: isDoctor ? () => _confirmAppointment(appt['id']) : null,
                showPatient: isDoctor,
                isDoctor: isDoctor,
              ).animate().fadeIn(delay: (80 * i).ms).slideY(begin: 0.08);
            }),
            if (showPagination) ...[
              const SizedBox(height: 8),
              PaginationBar(
                currentPage: _currentPage,
                totalCount: isDoctor ? _filteredAppointments.length : _totalCount,
                pageSize: _pageSize,
                hasNext: isDoctor ? _currentPage < _totalPages : _hasNext,
                hasPrev: isDoctor ? _currentPage > 1 : _hasPrev,
                onNext: (isDoctor ? _currentPage < _totalPages : _hasNext) ? () {
                  setState(() => _currentPage++);
                  if (!isDoctor) _loadAppointments(resetPage: false);
                } : null,
                onPrev: (isDoctor ? _currentPage > 1 : _hasPrev) ? () {
                  setState(() => _currentPage--);
                  if (!isDoctor) _loadAppointments(resetPage: false);
                } : null,
              ),
            ],
            const SizedBox(height: 80),
          ],
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
  final VoidCallback? onConfirm;
  final bool showPatient;
  final bool isDoctor;

  const _AppointmentCard({
    required this.appointment,
    required this.index,
    required this.isLast,
    required this.onCancel,
    this.onConfirm,
    this.showPatient = false,
    this.isDoctor = false,
  });

  @override
  State<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<_AppointmentCard> {
  bool _expanded = false;

  Color get _statusColor {
    final success = widget.isDoctor ? DoctorColors.success : AppColors.success;
    final warning = widget.isDoctor ? DoctorColors.warning : AppColors.warning;
    final error = widget.isDoctor ? DoctorColors.error : AppColors.error;
    final sec = widget.isDoctor ? DoctorColors.textSecondary : AppColors.textSecondary;
    switch (widget.appointment['status'] ?? '') {
      case 'CONFIRMED': return success;
      case 'PENDING': return warning;
      case 'CANCELLED': return error;
      default: return sec;
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

    String displayName = doctorName;
    String displaySub = doctorSpec;
    if (widget.showPatient) {
      final patientObj = appt['patient'];
      if (patientObj is Map) {
        final userObj = patientObj['user'];
        if (userObj is Map) {
          displayName = '${userObj['first_name'] ?? ''} ${userObj['last_name'] ?? ''}'.trim();
          if (displayName.isEmpty) displayName = 'Patient';
        } else {
          displayName = 'Patient';
        }
      } else {
        displayName = appt['patient_name']?.toString() ?? 'Patient';
      }
      displaySub = '';
    }

    final reason = appt['reason'];
    final status = appt['status'] ?? '';
    final canCancel = status == 'PENDING' || status == 'CONFIRMED';

    // Doctor uses green accent colors, patient uses warm colors
    final doctorAccents = [
      const Color(0xFF2E7D32),
      const Color(0xFF00897B),
      const Color(0xFF388E3C),
      const Color(0xFF00796B),
      const Color(0xFF1B5E20),
    ];
    final patientAccents = [
      const Color(0xFFFF8FA3),
      const Color(0xFFFFB74D),
      const Color(0xFF80CBC4),
      const Color(0xFFCE93D8),
      const Color(0xFF90CAF9),
    ];
    final accentColors = widget.isDoctor ? doctorAccents : patientAccents;
    final accentColor = accentColors[widget.index % accentColors.length];
    final primary = widget.isDoctor ? DoctorColors.primary : AppColors.primary;
    final bgColor = widget.isDoctor ? DoctorColors.background : AppColors.background;
    final textPrimary = widget.isDoctor ? DoctorColors.textPrimary : AppColors.textPrimary;
    final textSec = widget.isDoctor ? DoctorColors.textSecondary : AppColors.textSecondary;
    final textLight = widget.isDoctor ? DoctorColors.textLight : AppColors.textLight;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: accentColor.withAlpha(widget.isDoctor ? 50 : 30), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              // Colored top accent bar — thicker for doctor
              Container(
                height: widget.isDoctor ? 5 : 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDoctor
                        ? [DoctorColors.primaryDark, DoctorColors.primary, DoctorColors.accent]
                        : [accentColor, accentColor.withAlpha(120)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar with initials for doctor
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor.withAlpha(60), accentColor.withAlpha(30)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: widget.isDoctor
                              ? Center(
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
                                  ),
                                )
                              : Icon(Iconsax.user, size: 26, color: accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                              const SizedBox(height: 4),
                              if (displaySub.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(displaySub,
                                    style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              if (widget.isDoctor && reason != null && reason.toString().isNotEmpty)
                                Text(reason.toString(),
                                  style: TextStyle(color: textSec, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
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
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: widget.isDoctor ? Border.all(color: DoctorColors.primary.withAlpha(30)) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.calendar_1, size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                            ),
                            const Spacer(),
                            Container(width: 1, height: 16, color: textLight),
                            const Spacer(),
                            Icon(Iconsax.clock, size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    // Expandable detail
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _expanded ? Column(children: [
                        if (!widget.isDoctor && reason != null && reason.toString().isNotEmpty) ...[
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
                                Icon(Iconsax.note_text, size: 16, color: textSec),
                                const SizedBox(width: 8),
                                Expanded(child: Text(reason.toString(),
                                  style: TextStyle(color: textSec, fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                        if (canCancel) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.showPatient && status == 'PENDING') ...[
                                _actionBtn(
                                  icon: Iconsax.tick_circle,
                                  label: 'Confirmer',
                                  color: widget.isDoctor ? DoctorColors.success : AppColors.success,
                                  onTap: widget.onConfirm,
                                ),
                                const SizedBox(width: 8),
                              ],
                              _actionBtn(
                                icon: Iconsax.calendar_remove,
                                label: 'Annuler',
                                color: widget.isDoctor ? DoctorColors.error : AppColors.error,
                                onTap: widget.onCancel,
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
                        child: Icon(Iconsax.arrow_down, size: 16, color: textLight),
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

  Widget _actionBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: color.withAlpha(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
