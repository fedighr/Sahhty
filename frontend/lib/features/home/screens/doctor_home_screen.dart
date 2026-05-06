import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

// ── Doctor theme colors (Green) ──────────────────────────────────────
class DoctorColors {
  static const Color primary       = Color(0xFF2E7D32);
  static const Color primaryDark   = Color(0xFF1B5E20);
  static const Color primaryLight  = Color(0xFFE8F5E9);
  static const Color primaryMid    = Color(0xFF388E3C);
  static const Color accent        = Color(0xFF00897B);
  static const Color accentLight   = Color(0xFFE0F2F1);
  static const Color background    = Color(0xFFF1F8F1);
  static const Color surface       = Colors.white;
  static const Color textPrimary   = Color(0xFF1B2E1B);
  static const Color textSecondary = Color(0xFF5A6A5A);
  static const Color textLight     = Color(0xFFADB5AD);
  static const Color success       = Color(0xFF2E7D32);
  static const Color successLight  = Color(0xFFE8F5E9);
  static const Color warning       = Color(0xFFF57F17);
  static const Color warningLight  = Color(0xFFFFF3E0);
  static const Color error         = Color(0xFFB71C1C);
  static const Color errorLight    = Color(0xFFFFEBEE);
}

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen> {
  Map<String, dynamic>? _doctorData;
  String? _profileError;
  List<dynamic> _appointments     = [];
  List<dynamic> _schedule         = [];
  bool _loadingProfile            = true;
  bool _loadingAppointments       = true;
  bool _loadingSchedule           = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth     = ref.read(authProvider);
    final doctorId = int.tryParse(auth.doctorId ?? '') ?? 0;

    if (doctorId == 0) {
      if (mounted) setState(() { _loadingProfile = false; _loadingAppointments = false; _loadingSchedule = false; });
      return;
    }

    final doctorSvc = ref.read(doctorServiceProvider);
    final apptSvc   = ref.read(appointmentServiceProvider);

    try {
      final res = await doctorSvc.getDoctorById(doctorId);
      if (mounted) setState(() {
        _doctorData    = res['success'] == true ? res['doctor'] : null;
        // Don't show error for unverified - use auth fallback in UI
        _profileError  = null;
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loadingProfile = false; });
    }

    try {
      final res = await apptSvc.getDoctorTodayAppointments(doctorId);
      if (mounted) setState(() {
        _appointments        = res['appointments'] as List<dynamic>? ?? [];
        _loadingAppointments = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAppointments = false);
    }

    try {
      final res = await doctorSvc.getDoctorSchedule(doctorId);
      if (mounted) setState(() {
        _schedule        = res['schedules'] as List<dynamic>? ?? [];
        _loadingSchedule = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadingProfile      = true;
      _loadingAppointments = true;
      _loadingSchedule     = true;
      _profileError        = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.name ?? 'Médecin';

    return Scaffold(
      backgroundColor: DoctorColors.background,
      body: RefreshIndicator(
        color: DoctorColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(name),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  _buildQuickActions(context),
                  _buildSectionTitle('Rendez-vous à venir', Iconsax.calendar, onSeeAll: () => context.go('/doctor-appointments')),
                  _buildAppointmentsList(),
                  _buildSectionTitle('Mon planning', Iconsax.clock),
                  _buildSchedulePreview(),
                  _buildSectionTitle('Mon profil', Iconsax.user),
                  _buildProfileCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return SliverAppBar(
      expandedHeight: 190,
      floating: false,
      pinned: true,
      backgroundColor: DoctorColors.primary,
      elevation: 0,
      actions: [

        IconButton(icon: const Icon(Iconsax.setting_2, color: Colors.white, size: 22), onPressed: () => context.go('/doctor-settings')),
        IconButton(
          icon: const Icon(Iconsax.logout, color: Colors.white, size: 22),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) context.go('/login');
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting 👋', style: const TextStyle(color: Colors.white70, fontSize: 14)).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 4),
                  Text('Dr. $name', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))
                      .animate().slideX(begin: -0.2, duration: 500.ms),
                  const SizedBox(height: 8),
                  if (!_loadingProfile && _doctorData != null)
                    Wrap(
                      spacing: 8,
                      children: [
                        _headerChip(Iconsax.award, _doctorData?['speciality'] ?? 'Médecin'),
                        _headerChip(Iconsax.location, _doctorData?['ville'] ?? ''),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }

  Widget _buildStatsRow() {
    final total          = _appointments.length;
    final confirmed      = _appointments.where((a) => a['status'] == 'CONFIRMED').length;
    final pending        = _appointments.where((a) => a['status'] == 'PENDING').length;
    final activeSchedule = _schedule.where((s) => s['is_available'] == true).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _statCard('RDV', '$total',     Iconsax.calendar,   DoctorColors.primary, 0),
          const SizedBox(width: 8),
          _statCard('Confirmés', '$confirmed', Iconsax.tick_circle, DoctorColors.success, 80),
          const SizedBox(width: 8),
          _statCard('Attente', '$pending', Iconsax.clock, DoctorColors.warning, 160),
          const SizedBox(width: 8),
          _statCard('Jours actifs', '$activeSchedule', Iconsax.timer_1, DoctorColors.accent, 240),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, int delay) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: DoctorColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('Mes RDV',      Iconsax.calendar,    () => context.go('/doctor-appointments')),
      ('Paramtres',   Iconsax.setting_2,   () => context.go('/doctor-settings')),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Actions rapides', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: DoctorColors.textPrimary)),
        const SizedBox(height: 10),
        Row(
          children: actions.asMap().entries.map((e) {
            final i = e.key;
            final (label, icon, onTap) = e.value;
            return [
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: DoctorColors.primary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(height: 5),
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                    ]),
                  ).animate().fadeIn(delay: (i * 60).ms).scale(begin: const Offset(0.9, 0.9)),
                ),
              ),
              if (i < actions.length - 1) const SizedBox(width: 8),
            ];
          }).expand((w) => w).toList(),
        ),
      ]),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: DoctorColors.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: DoctorColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DoctorColors.textPrimary))),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('Voir tout', style: TextStyle(fontSize: 12, color: DoctorColors.primary, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _buildAppointmentsList() {
    if (_loadingAppointments) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: DoctorColors.primary)));
    }
    if (_appointments.isEmpty) {
      return _emptyCard(Iconsax.calendar_1, 'Aucun rendez-vous à venir', 'Vos prochains rendez-vous apparaîtront ici');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _appointments.length,
      itemBuilder: (context, i) => _AppointmentCard(appointment: _appointments[i], onRefresh: _refresh)
          .animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.1),
    );
  }

  Widget _buildSchedulePreview() {
    if (_loadingSchedule) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: DoctorColors.primary)));
    }
    if (_schedule.isEmpty) {
      return _emptyCard(Iconsax.clock, 'Aucun horaire défini', 'Configurez votre planning de consultation');
    }
    const dayLabels = {
      'MONDAY': 'Lun', 'TUESDAY': 'Mar', 'WEDNESDAY': 'Mer',
      'THURSDAY': 'Jeu', 'FRIDAY': 'Ven', 'SATURDAY': 'Sam', 'SUNDAY': 'Dim',
    };
    const dayFull = {
      'MONDAY': 'Lundi', 'TUESDAY': 'Mardi', 'WEDNESDAY': 'Mercredi',
      'THURSDAY': 'Jeudi', 'FRIDAY': 'Vendredi', 'SATURDAY': 'Samedi', 'SUNDAY': 'Dimanche',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _schedule.take(7).map((s) {
              final available = s['is_available'] == true;
              final dayShort  = dayLabels[s['day_of_week']] ?? s['day_of_week'];
              return Column(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: available ? DoctorColors.primary : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(dayShort, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: available ? Colors.white : DoctorColors.textLight))),
                ),
                const SizedBox(height: 4),
                Icon(available ? Iconsax.tick_circle : Iconsax.close_circle, size: 12, color: available ? DoctorColors.success : DoctorColors.textLight),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          ..._schedule.where((s) => s['is_available'] == true).take(3).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Iconsax.clock, size: 14, color: DoctorColors.primary),
              const SizedBox(width: 8),
              Text(dayFull[s['day_of_week']] ?? s['day_of_week'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DoctorColors.textPrimary)),
              const Spacer(),
              Text('${s['start_time']} – ${s['end_time']}', style: const TextStyle(fontSize: 12, color: DoctorColors.textSecondary)),
            ]),
          )),
        ]),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildProfileCard() {
    if (_loadingProfile) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: DoctorColors.primary)));
    }
    if (_doctorData == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: DoctorColors.warningLight, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Iconsax.timer_1, color: DoctorColors.warning, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('En attente de vérification', style: TextStyle(fontWeight: FontWeight.bold, color: DoctorColors.textPrimary)),
              SizedBox(height: 4),
              Text('Votre compte sera activé après validation par l\'administration.',
                  style: TextStyle(fontSize: 12, color: DoctorColors.textSecondary, height: 1.4)),
            ])),
          ]),
        ).animate().fadeIn(),
      );
    }
    final d       = _doctorData!;
    final name    = '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF388E3C)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withAlpha(40),
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dr. $name', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(d['speciality'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [
                  _profileChip('${d['experience'] ?? 0} ans'),
                  _profileChip('${d['consultation_price'] ?? '–'} TND'),
                ]),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _infoRow(Iconsax.location, 'Ville',    d['ville']   ?? '–'),
              _infoRow(Iconsax.home_2,   'Adresse',  d['address'] ?? '–'),
              _infoRow(Iconsax.sms,      'Email',    d['email']   ?? '–'),
              if ((d['phone'] ?? '').toString().isNotEmpty)
                _infoRow(Iconsax.call, 'Téléphone', d['phone']),
              if ((d['bio'] ?? '').toString().isNotEmpty) ...[
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(d['bio'], style: const TextStyle(fontSize: 13, color: DoctorColors.textSecondary, height: 1.5)),
                ),
              ],
            ]),
          ),
        ]),
      ).animate().fadeIn(delay: 100.ms),
    );
  }

  Widget _profileChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
  );

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: DoctorColors.primary),
        const SizedBox(width: 10),
        Text('$label :', style: const TextStyle(color: DoctorColors.textSecondary, fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: DoctorColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _emptyCard(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(children: [
          Icon(icon, size: 48, color: DoctorColors.textLight),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: DoctorColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: DoctorColors.textLight, fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Appointment Card ──────────────────────────────────────────────────
class _AppointmentCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onRefresh;
  const _AppointmentCard({required this.appointment, required this.onRefresh});

  @override
  ConsumerState<_AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends ConsumerState<_AppointmentCard> {
  bool _loading = false;

  String _getPatientName() {
    final patient = widget.appointment['patient'];
    if (patient is Map) {
      final user = patient['user'];
      if (user is Map) {
        final fn = user['first_name'] ?? '';
        final ln = user['last_name']  ?? '';
        return '$fn $ln'.trim().isNotEmpty ? '$fn $ln'.trim() : 'Patient';
      }
    }
    return widget.appointment['patient_name'] ?? 'Patient';
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'CONFIRMED': return DoctorColors.success;
      case 'PENDING':   return DoctorColors.warning;
      case 'CANCELLED': return DoctorColors.error;
      default:          return DoctorColors.textLight;
    }
  }

  Color _statusBg(String? s) {
    switch (s) {
      case 'CONFIRMED': return DoctorColors.successLight;
      case 'PENDING':   return DoctorColors.warningLight;
      case 'CANCELLED': return DoctorColors.errorLight;
      default:          return DoctorColors.primaryLight;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'CONFIRMED': return 'Confirmé';
      case 'PENDING':   return 'En attente';
      case 'CANCELLED': return 'Annulé';
      default:          return s ?? '–';
    }
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    final id  = widget.appointment['id'] as int? ?? 0;
    await ref.read(appointmentServiceProvider).confirmAppointment(id);
    widget.onRefresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Annuler le rendez-vous', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Annuler le RDV avec ${_getPatientName()} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DoctorColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    final id = widget.appointment['id'] as int? ?? 0;
    await ref.read(appointmentServiceProvider).cancelAppointment(id, 'DOCTOR');
    widget.onRefresh();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appt        = widget.appointment;
    final status      = appt['status'] as String?;
    final dateStr     = appt['appointment_date'] as String? ?? '';
    final reason      = appt['reason'] as String?;
    final patientName = _getPatientName();
    final statusColor = _statusColor(status);
    final statusBg    = _statusBg(status);
    final initial     = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';

    String displayDate = '';
    String displayTime = '';
    try {
      final dt   = DateTime.parse(dateStr).toLocal();
      displayDate = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      displayTime = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      displayTime = dateStr.length >= 16 ? dateStr.substring(11, 16) : dateStr;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: statusColor.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: DoctorColors.primaryLight,
              child: Text(initial, style: const TextStyle(color: DoctorColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, color: DoctorColors.textPrimary, fontSize: 14)),
              if (reason != null && reason.isNotEmpty)
                Text(reason, style: const TextStyle(fontSize: 12, color: DoctorColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Iconsax.calendar, size: 13, color: DoctorColors.primary),
            const SizedBox(width: 4),
            Text(displayDate, style: const TextStyle(fontSize: 12, color: DoctorColors.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Iconsax.clock, size: 13, color: DoctorColors.primary),
            const SizedBox(width: 4),
            Text(displayTime, style: const TextStyle(fontSize: 12, color: DoctorColors.textSecondary)),
            const Spacer(),
            if (_loading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: DoctorColors.primary))
            else ...[
              if (status == 'PENDING') ...[
                _actionBtn('Confirmer', DoctorColors.success, _confirm),
                const SizedBox(width: 6),
              ],
              if (status == 'PENDING' || status == 'CONFIRMED')
                _actionBtn('Annuler', DoctorColors.error, _cancel),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }
}
