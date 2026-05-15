import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/providers/refresh_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

// ── Constants ────────────────────────────────────────────────────────────────
class _Days {
  static const list = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
  ];
  static const labelsFr = {
    'MONDAY': 'Lundi',
    'TUESDAY': 'Mardi',
    'WEDNESDAY': 'Mercredi',
    'THURSDAY': 'Jeudi',
    'FRIDAY': 'Vendredi',
    'SATURDAY': 'Samedi',
    'SUNDAY': 'Dimanche',
  };
  static const labelsShort = {
    'MONDAY': 'LUN',
    'TUESDAY': 'MAR',
    'WEDNESDAY': 'MER',
    'THURSDAY': 'JEU',
    'FRIDAY': 'VEN',
    'SATURDAY': 'SAM',
    'SUNDAY': 'DIM',
  };
  static const gradients = {
    'MONDAY':    [Color(0xFF81C784), Color(0xFF4CAF50)],
    'TUESDAY':   [Color(0xFF80CBC4), Color(0xFF26A69A)],
    'WEDNESDAY': [Color(0xFF90CAF9), Color(0xFF1E88E5)],
    'THURSDAY':  [Color(0xFFCE93D8), Color(0xFF8E24AA)],
    'FRIDAY':    [Color(0xFFFFCC80), Color(0xFFF57C00)],
    'SATURDAY':  [Color(0xFFEF9A9A), Color(0xFFE53935)],
    'SUNDAY':    [Color(0xFFA5D6A7), Color(0xFF388E3C)],
  };
}

// ── Screen ────────────────────────────────────────────────────────────────────
class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  ConsumerState<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // State per day: available, start, end, pause start, pause end
  final Map<String, _DayState> _dayStates = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _Days.list.length, vsync: this);
    for (final d in _Days.list) {
      _dayStates[d] = _DayState(day: d);
    }
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authProvider);
    final doctorId = int.tryParse(auth.doctorId ?? '') ?? 0;
    if (doctorId == 0) {
      setState(() { _loading = false; _error = 'ID médecin introuvable.'; });
      return;
    }

    final result = await ref.read(doctorServiceProvider).getDoctorSchedule(doctorId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final schedules = result['schedules'] as List? ?? [];
        for (final s in schedules) {
          final day = s['day_of_week'] as String? ?? '';
          if (_dayStates.containsKey(day)) {
            _dayStates[day] = _DayState.fromApi(s);
          }
        }
      } else {
        _error = result['message'] ?? 'Erreur de chargement';
      }
    });
  }

  Future<void> _saveSchedule() async {
    setState(() { _saving = true; _error = null; });
    final auth = ref.read(authProvider);
    final doctorId = int.tryParse(auth.doctorId ?? '') ?? 0;

    final payload = _dayStates.entries
        .where((e) => e.value.isAvailable)
        .map((e) => e.value.toPayload(doctorId))
        .toList();

    if (payload.isEmpty) {
      // Send at least all days as unavailable
      final allPayload = _dayStates.entries
          .map((e) => e.value.toPayload(doctorId))
          .toList();
      final result = await ref.read(doctorServiceProvider).addDoctorSchedule(allPayload);
      if (!mounted) return;
      setState(() => _saving = false);
      _handleSaveResult(result);
      return;
    }

    final result = await ref.read(doctorServiceProvider).addDoctorSchedule(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    _handleSaveResult(result);
  }

  void _handleSaveResult(Map<String, dynamic> result) {
    if (result['success'] == true || result['status'] == 201) {
      _showSuccessSnack();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        // Trigger reload of DoctorHomeScreen
        ref.read(doctorHomeRefreshProvider.notifier).state++;
        context.go('/doctor-home');
      });
    } else {
      setState(() => _error = result['message'] ?? 'Erreur lors de la sauvegarde');
    }
  }

  void _showSuccessSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Horaire sauvegardé avec succès !'),
        ]),
        backgroundColor: DoctorColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDays = _dayStates.values.where((d) => d.isAvailable).length;

    return Scaffold(
      backgroundColor: DoctorColors.background,
      body: Column(
        children: [
          _buildHeader(activeDays),
          _buildWeekOverview(),
          _buildTabBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: DoctorColors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: _Days.list.map((d) => _DayPanel(
                      state: _dayStates[d]!,
                      onChanged: (ns) => setState(() => _dayStates[d] = ns),
                    )).toList(),
                  ),
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DoctorColors.errorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Iconsax.warning_2, color: DoctorColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: DoctorColors.error, fontSize: 12))),
              ]),
            ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(int activeDays) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF66BB6A), Color(0xFF81C784), Color(0xFFA5D6A7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.arrow_left, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mon Horaire',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
                        .animate().fadeIn(duration: 400.ms),
                    Text('$activeDays jour${activeDays > 1 ? 's' : ''} de consultation actif${activeDays > 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13))
                        .animate().fadeIn(delay: 150.ms),
                  ],
                ),
              ),
              // Legend dot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$activeDays/7', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ).animate().slideY(begin: -0.2, duration: 500.ms),
        ),
      ),
    );
  }

  Widget _buildWeekOverview() {
    return Container(
      color: const Color(0xFF66BB6A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _Days.list.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value;
          final st = _dayStates[day]!;
          final isSelected = _tabController.index == i;

          return GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 38,
              height: 52,
              decoration: BoxDecoration(
                color: st.isAvailable
                    ? Colors.white
                    : Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: st.isAvailable
                    ? [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _Days.labelsShort[day]!.substring(0, 1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: st.isAvailable ? DoctorColors.primary : Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: st.isAvailable ? DoctorColors.success : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: DoctorColors.primary,
        indicatorWeight: 3,
        labelColor: DoctorColors.primary,
        unselectedLabelColor: DoctorColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        onTap: (_) => setState(() {}),
        tabs: _Days.list.map((d) {
          final st = _dayStates[d]!;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (st.isAvailable)
                  Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: const BoxDecoration(color: DoctorColors.success, shape: BoxShape.circle),
                  ),
                Text(_Days.labelsFr[d]!.substring(0, 3)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _saving ? null : _saveSchedule,
          style: ElevatedButton.styleFrom(
            backgroundColor: DoctorColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: DoctorColors.primary.withAlpha(80),
          ),
          child: _saving
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.tick_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Sauvegarder l\'horaire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
        ).animate().fadeIn(delay: 300.ms),
      ),
    );
  }
}

// ── Day State ─────────────────────────────────────────────────────────────────
class _DayState {
  final String day;
  bool isAvailable;
  bool isOnLeave;
  TimeOfDay startTime;
  TimeOfDay endTime;
  bool hasPause;
  TimeOfDay pauseStart;
  TimeOfDay pauseEnd;

  _DayState({
    required this.day,
    this.isAvailable = false,
    this.isOnLeave = false,
    this.startTime = const TimeOfDay(hour: 8, minute: 0),
    this.endTime = const TimeOfDay(hour: 17, minute: 0),
    this.hasPause = false,
    this.pauseStart = const TimeOfDay(hour: 12, minute: 0),
    this.pauseEnd = const TimeOfDay(hour: 13, minute: 0),
  });

  factory _DayState.fromApi(Map<String, dynamic> s) {
    TimeOfDay parseTime(String? t) {
      if (t == null || t.isEmpty) return const TimeOfDay(hour: 8, minute: 0);
      final parts = t.split(':');
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0);
    }

    // If start_time exists but is_available is false → day is configured but on leave
    final hasHours = s['start_time'] != null && s['start_time'].toString().isNotEmpty;
    final apiAvailable = s['is_available'] == true;

    return _DayState(
      day: s['day_of_week'] ?? '',
      isAvailable: apiAvailable || hasHours,   // show toggle ON if hours exist
      isOnLeave: hasHours && !apiAvailable,     // on leave if hours exist but unavailable
      startTime: parseTime(s['start_time']),
      endTime: parseTime(s['end_time']),
      hasPause: s['pause_start_time'] != null && s['pause_start_time'].toString().isNotEmpty,
      pauseStart: parseTime(s['pause_start_time']),
      pauseEnd: parseTime(s['pause_end_time']),
    );
  }

  _DayState copyWith({
    bool? isAvailable,
    bool? isOnLeave,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? hasPause,
    TimeOfDay? pauseStart,
    TimeOfDay? pauseEnd,
  }) {
    return _DayState(
      day: day,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnLeave: isOnLeave ?? this.isOnLeave,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hasPause: hasPause ?? this.hasPause,
      pauseStart: pauseStart ?? this.pauseStart,
      pauseEnd: pauseEnd ?? this.pauseEnd,
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Map<String, dynamic> toPayload(int doctorId) => {
    'doctor_id': doctorId,
    'day_of_week': day,
    'start_time': _fmt(startTime),
    'end_time': _fmt(endTime),
    'pause_start_time': hasPause ? _fmt(pauseStart) : null,
    'pause_end_time': hasPause ? _fmt(pauseEnd) : null,
    // is_available = false when day is disabled OR when on leave
    'is_available': isAvailable && !isOnLeave,
  };
}

// ── Day Panel ─────────────────────────────────────────────────────────────────
class _DayPanel extends StatelessWidget {
  final _DayState state;
  final ValueChanged<_DayState> onChanged;

  const _DayPanel({required this.state, required this.onChanged});

  Future<void> _pickTime(BuildContext context, TimeOfDay initial, ValueChanged<TimeOfDay> onPick) async {
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: DoctorColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) onPick(t);
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final grad = _Days.gradients[state.day] ?? [DoctorColors.primary, DoctorColors.primaryDark];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card with day toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: grad[0].withAlpha(80), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_Days.labelsShort[state.day]!.substring(0, 1),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_Days.labelsFr[state.day]!,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      state.isAvailable ? 'Jour de consultation actif' : 'Jour non travaillé',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ),
                // Toggle switch
                  Transform.scale(
                  scale: 1.1,
                  child: Switch(
                    value: state.isAvailable,
                    onChanged: (v) => onChanged(state.copyWith(isAvailable: v)),
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withAlpha(80),
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.white.withAlpha(40),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96)),

          const SizedBox(height: 20),

          if (!state.isAvailable) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Iconsax.close_circle, size: 28, color: Colors.grey.shade300),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Jour non travaillé',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('Activez ce jour pour définir vos horaires',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    ]),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ] else ...[
            // ── Congé card ────────────────────────────────────────────────
            _CongeCard(
              isOnLeave: state.isOnLeave,
              onChanged: (v) => onChanged(state.copyWith(isOnLeave: v)),
            ),
            const SizedBox(height: 16),

            if (!state.isOnLeave) ...[
            // Working hours card
            _buildTimeCard(
              context,
              icon: Iconsax.clock,
              title: 'Heures de travail',
              color: grad[0],
              children: [
                _TimeRow(
                  label: 'Heure de début',
                  time: state.startTime,
                  color: grad[0],
                  onTap: () => _pickTime(context, state.startTime, (t) => onChanged(state.copyWith(startTime: t))),
                ),
                const SizedBox(height: 12),
                // Arrow between times
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Iconsax.arrow_down, size: 16, color: Colors.grey.shade400),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ]),
                const SizedBox(height: 12),
                _TimeRow(
                  label: 'Heure de fin',
                  time: state.endTime,
                  color: grad[0],
                  onTap: () => _pickTime(context, state.endTime, (t) => onChanged(state.copyWith(endTime: t))),
                ),
                const SizedBox(height: 16),
                // Duration chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: grad[0].withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Iconsax.timer_1, size: 14, color: grad[0]),
                    const SizedBox(width: 6),
                    Text(
                      _calcDuration(state.startTime, state.endTime),
                      style: TextStyle(fontSize: 12, color: grad[0], fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pause card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.coffee, size: 18, color: Color(0xFFF57C00)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pause déjeuner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DoctorColors.textPrimary)),
                    Text('Optionnel', style: TextStyle(fontSize: 11, color: DoctorColors.textSecondary)),
                  ])),
                  Switch(
                    value: state.hasPause,
                    onChanged: (v) => onChanged(state.copyWith(hasPause: v)),
                    activeThumbColor: const Color(0xFFF57C00),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ]),
                if (state.hasPause) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  _TimeRow(
                    label: 'Début de pause',
                    time: state.pauseStart,
                    color: const Color(0xFFF57C00),
                    onTap: () => _pickTime(context, state.pauseStart, (t) => onChanged(state.copyWith(pauseStart: t))),
                  ),
                  const SizedBox(height: 12),
                  _TimeRow(
                    label: 'Fin de pause',
                    time: state.pauseEnd,
                    color: const Color(0xFFF57C00),
                    onTap: () => _pickTime(context, state.pauseEnd, (t) => onChanged(state.copyWith(pauseEnd: t))),
                  ),
                ],
              ]),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Summary card
            _buildSummaryCard(state, grad[0]),
          ],   // end if (!state.isOnLeave)

          ],   // end else (isAvailable)

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DoctorColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    ).animate().fadeIn(delay: 60.ms);
  }

  Widget _buildSummaryCard(_DayState st, Color color) {
    final slots = _estimateSlots(st);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(15), color.withAlpha(8)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Début', value: _fmtTime(st.startTime), icon: Iconsax.sun_1, color: color),
          _divider(),
          _SummaryItem(label: 'Fin', value: _fmtTime(st.endTime), icon: Iconsax.moon, color: color),
          _divider(),
          _SummaryItem(label: 'Créneaux', value: '$slots', icon: Iconsax.calendar_tick, color: color),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.grey.shade200);

  String _calcDuration(TimeOfDay start, TimeOfDay end) {
    int mins = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
    if (mins <= 0) return '0h';
    final h = mins ~/ 60;
    final m = mins % 60;
    return h > 0 ? (m > 0 ? '${h}h${m}min' : '${h}h') : '${m}min';
  }

  int _estimateSlots(_DayState st) {
    int workMins = (st.endTime.hour * 60 + st.endTime.minute) -
        (st.startTime.hour * 60 + st.startTime.minute);
    if (st.hasPause) {
      int pauseMins = (st.pauseEnd.hour * 60 + st.pauseEnd.minute) -
          (st.pauseStart.hour * 60 + st.pauseStart.minute);
      workMins -= pauseMins.clamp(0, 999);
    }
    return (workMins / 30).floor().clamp(0, 99);
  }
}

// ── Congé Card ────────────────────────────────────────────────────────────────
class _CongeCard extends StatelessWidget {
  final bool isOnLeave;
  final ValueChanged<bool> onChanged;

  const _CongeCard({required this.isOnLeave, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isOnLeave ? const Color(0xFFFFF3E0) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOnLeave ? const Color(0xFFF57C00).withAlpha(120) : Colors.grey.shade200,
          width: isOnLeave ? 1.5 : 1,
        ),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isOnLeave ? const Color(0xFFF57C00).withAlpha(30) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.calendar_remove,
              size: 22,
              color: isOnLeave ? const Color(0xFFF57C00) : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Mode Congé',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isOnLeave ? const Color(0xFFF57C00) : DoctorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isOnLeave
                    ? 'Ce jour est en congé — horaire conservé'
                    : 'Activer pour marquer ce jour comme congé',
                style: TextStyle(
                  fontSize: 11,
                  color: isOnLeave ? const Color(0xFFF57C00).withAlpha(200) : DoctorColors.textSecondary,
                ),
              ),
            ]),
          ),
          Switch(
            value: isOnLeave,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFF57C00),
            inactiveThumbColor: Colors.grey.shade400,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ── Time Row ──────────────────────────────────────────────────────────────────
class _TimeRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;

  const _TimeRow({required this.label, required this.time, required this.color, required this.onTap});

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(Iconsax.clock, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: DoctorColors.textSecondary)),
            const SizedBox(height: 2),
            Text(_fmt(time),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ])),
          Icon(Iconsax.edit_2, size: 16, color: color.withAlpha(180)),
        ]),
      ),
    );
  }
}

// ── Summary Item ──────────────────────────────────────────────────────────────
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: DoctorColors.textSecondary)),
      ],
    );
  }
}
