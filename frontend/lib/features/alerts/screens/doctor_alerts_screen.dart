import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

// ── Doctor alert screen ──────────────────────────────────────────────
class DoctorAlertsScreen extends ConsumerStatefulWidget {
  const DoctorAlertsScreen({super.key});
  @override
  ConsumerState<DoctorAlertsScreen> createState() => _DoctorAlertsScreenState();
}

class _DoctorAlertsScreenState extends ConsumerState<DoctorAlertsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Appointments ─────────────────────────────────────────────────
  List<dynamic> _pendingAppts  = [];
  List<dynamic> _confirmedAppts = [];
  bool _loadingAppts           = true;

  // ── Access requests ──────────────────────────────────────────────
  // We load doctor's patients list and filter PENDING
  // (backend: GET /medical_files/MedicalFileService/{doctorId}/get_doctor_patients/)
  List<dynamic> _accessRequests = [];
  bool _loadingAccess           = true;

  // ── System alerts ────────────────────────────────────────────────
  List<dynamic> _systemAlerts  = [];
  bool _loadingSystem          = true;
  int _alertPage               = 1;
  bool _alertHasNext           = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth     = ref.read(authProvider);
    final doctorId = int.tryParse(auth.doctorId ?? '') ?? 0;
    final userId   = int.tryParse(auth.userId   ?? '') ?? 0;
    if (doctorId == 0) return;

    // 1 — Appointments
    final apptSvc  = ref.read(appointmentServiceProvider);
    final apptRes  = await apptSvc.getDoctorAllAppointments(doctorId);
    if (mounted) {
      final list = (apptRes['appointments'] as List<dynamic>? ?? []);
      setState(() {
        _pendingAppts   = list.where((a) => a['status'] == 'PENDING').toList();
        _confirmedAppts = list.where((a) => a['status'] == 'CONFIRMED').toList();
        _loadingAppts   = false;
      });
    }

    // 2 — Access requests
    final medSvc = ref.read(medicalFileServiceProvider);
    final accessRes = await medSvc.getDoctorPatients(doctorId);
    if (mounted) {
      final patients = accessRes['patients'] as List<dynamic>? ?? [];
      setState(() {
        _accessRequests = patients; // already filtered to accepted; pending comes from patient side
        _loadingAccess  = false;
      });
    }

    // 3 — System alerts (doctor's user alerts)
    if (userId > 0) {
      final alertSvc  = ref.read(alertServiceProvider);
      final alertRes  = await alertSvc.getAlertsByUser(userId, page: 1);
      if (mounted) {
        setState(() {
          _systemAlerts  = alertRes['alerts'] ?? [];
          _alertHasNext  = alertRes['next'] != null;
          _loadingSystem = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingSystem = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadingAppts = _loadingAccess = _loadingSystem = true;
      _alertPage = 1;
    });
    await _load();
  }

  Future<void> _confirmAppt(int id) async {
    await ref.read(appointmentServiceProvider).confirmAppointment(id);
    _refresh();
  }

  Future<void> _cancelAppt(int id) async {
    await ref.read(appointmentServiceProvider).cancelAppointment(id, 'DOCTOR');
    _refresh();
  }

  Future<void> _markRead(int alertId) async {
    await ref.read(alertServiceProvider).markAsRead(alertId);
    _refresh();
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pendingCount  = _pendingAppts.length;
    final unreadCount   = _systemAlerts.where((a) => a['status'] == 'NEW').length;

    return Scaffold(
      backgroundColor: DoctorColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: DoctorColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left, color: Colors.white),
              onPressed: () => context.go('/doctor-home'),
            ),
            title: const Text('Alertes & Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.refresh_2, color: Colors.white),
                onPressed: _refresh,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF66BB6A), Color(0xFF81C784), Color(0xFFA5D6A7)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 54, 16, 8),
                    child: Row(
                      children: [
                        _TopBadge(icon: Iconsax.calendar, label: 'En attente', count: pendingCount, color: DoctorColors.warning),
                        const SizedBox(width: 10),
                        _TopBadge(icon: Iconsax.notification, label: 'Non lues', count: unreadCount, color: DoctorColors.error),
                        const SizedBox(width: 10),
                        _TopBadge(icon: Iconsax.people, label: 'Patients', count: _accessRequests.length, color: DoctorColors.accent),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                tabs: [
                  Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Iconsax.calendar, size: 14),
                      const SizedBox(width: 4),
                      Text('RDV${pendingCount > 0 ? ' ($pendingCount)' : ''}'),
                    ]),
                  ),
                  const Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Iconsax.people, size: 14),
                      SizedBox(width: 4),
                      Text('Patients'),
                    ]),
                  ),
                  Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Iconsax.notification, size: 14),
                      const SizedBox(width: 4),
                      Text('Système${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentsTab(),
            _buildAccessTab(),
            _buildSystemTab(),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1 : Appointments ────────────────────────────────────────

  Widget _buildAppointmentsTab() {
    if (_loadingAppts) return _loader();
    if (_pendingAppts.isEmpty && _confirmedAppts.isEmpty) {
      return _emptyState(Iconsax.calendar_1, 'Aucun rendez-vous', 'Tous vos rendez-vous apparaîtront ici');
    }
    return RefreshIndicator(
      color: DoctorColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_pendingAppts.isNotEmpty) ...[
            _sectionHeader(Iconsax.clock, 'En attente de confirmation', DoctorColors.warning, _pendingAppts.length),
            ..._pendingAppts.asMap().entries.map((e) =>
              _ApptCard(appt: e.value, isPending: true, onConfirm: _confirmAppt, onCancel: _cancelAppt)
                .animate().fadeIn(delay: (e.key * 60).ms).slideX(begin: -0.1),
            ),
            const SizedBox(height: 16),
          ],
          if (_confirmedAppts.isNotEmpty) ...[
            _sectionHeader(Iconsax.tick_circle, 'Confirmés à venir', DoctorColors.success, _confirmedAppts.length),
            ..._confirmedAppts.asMap().entries.map((e) =>
              _ApptCard(appt: e.value, isPending: false, onConfirm: _confirmAppt, onCancel: _cancelAppt)
                .animate().fadeIn(delay: (e.key * 60).ms).slideX(begin: -0.1),
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB 2 : Access / Patients ──────────────────────────────────

  Widget _buildAccessTab() {
    if (_loadingAccess) return _loader();
    if (_accessRequests.isEmpty) {
      return _emptyState(Iconsax.people, 'Aucun patient', 'Vos patients autorisés apparaîtront ici');
    }
    return RefreshIndicator(
      color: DoctorColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(Iconsax.people, 'Patients avec accès accordé', DoctorColors.primary, _accessRequests.length),
          ..._accessRequests.asMap().entries.map((e) =>
            _PatientAccessCard(patient: e.value, onViewFile: () => context.push('/doctor/medical-access'))
              .animate().fadeIn(delay: (e.key * 60).ms).slideY(begin: 0.1),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3 : System ─────────────────────────────────────────────

  Widget _buildSystemTab() {
    if (_loadingSystem) return _loader();
    if (_systemAlerts.isEmpty) {
      return _emptyState(Iconsax.notification, 'Aucune alerte système', 'Tout est en ordre !');
    }
    return RefreshIndicator(
      color: DoctorColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._systemAlerts.asMap().entries.map((e) {
            final a = e.value as Map<String, dynamic>;
            return _SystemAlertCard(alert: a, onMarkRead: () => _markRead(a['id'] as int? ?? 0))
              .animate().fadeIn(delay: (e.key * 60).ms);
          }),
          if (_alertHasNext)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TextButton.icon(
                icon: const Icon(Iconsax.arrow_down_1),
                label: const Text('Charger plus'),
                style: TextButton.styleFrom(foregroundColor: DoctorColors.primary),
                onPressed: () async {
                  final userId = int.tryParse(ref.read(authProvider).userId ?? '') ?? 0;
                  if (userId == 0) return;
                  final res = await ref.read(alertServiceProvider).getAlertsByUser(userId, page: _alertPage + 1);
                  if (!mounted) return;
                  setState(() {
                    _alertPage++;
                    _systemAlerts.addAll(res['alerts'] ?? []);
                    _alertHasNext = res['next'] != null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  Widget _loader() => const Center(child: CircularProgressIndicator(color: DoctorColors.primary));

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: DoctorColors.primaryLight, borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 40, color: DoctorColors.primary),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: DoctorColors.textPrimary)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(fontSize: 13, color: DoctorColors.textSecondary)),
      ]).animate().fadeIn(),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ),
      ]),
    );
  }
}

// ── Badge en haut du header ──────────────────────────────────────────

class _TopBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _TopBadge({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: color.withAlpha(70), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 13),
          ),
          const SizedBox(height: 2),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.1)),
          Text(label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 9, height: 1.1), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, maxLines: 1),
        ]),
      ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

// ── Appointment card ─────────────────────────────────────────────────

class _ApptCard extends StatefulWidget {
  final Map<String, dynamic> appt;
  final bool isPending;
  final Future<void> Function(int) onConfirm;
  final Future<void> Function(int) onCancel;
  const _ApptCard({required this.appt, required this.isPending, required this.onConfirm, required this.onCancel});
  @override
  State<_ApptCard> createState() => _ApptCardState();
}

class _ApptCardState extends State<_ApptCard> {
  bool _busy = false;

  String _patientName() {
    final p = widget.appt['patient'];
    if (p is Map) {
      final u = p['user'];
      if (u is Map) return '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
    }
    return widget.appt['patient_name'] ?? 'Patient';
  }

  @override
  Widget build(BuildContext context) {
    final appt    = widget.appt;
    final dateStr = appt['appointment_date'] as String? ?? '';
    final reason  = appt['reason'] as String? ?? '';
    String displayDate = '', displayTime = '';
    try {
      final dt  = DateTime.parse(dateStr).toLocal();
      displayDate = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
      displayTime = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { displayDate = dateStr; }

    final borderColor = widget.isPending ? DoctorColors.warning : DoctorColors.success;
    final badgeColor  = widget.isPending ? DoctorColors.warning : DoctorColors.success;
    final badgeBg     = widget.isPending ? DoctorColors.warningLight : DoctorColors.successLight;
    final badgeLabel  = widget.isPending ? 'En attente' : 'Confirmé';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [BoxShadow(color: borderColor.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: DoctorColors.primaryLight,
              child: Text(_patientName().isNotEmpty ? _patientName()[0].toUpperCase() : 'P',
                  style: const TextStyle(color: DoctorColors.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_patientName(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (reason.isNotEmpty)
                Text(reason, style: const TextStyle(fontSize: 12, color: DoctorColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
              child: Text(badgeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor)),
            ),
          ]),
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
            if (_busy)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: DoctorColors.primary))
            else if (widget.isPending) ...[
              _btn('Confirmer', DoctorColors.success, () async {
                setState(() => _busy = true);
                await widget.onConfirm(appt['id'] as int? ?? 0);
              }),
              const SizedBox(width: 6),
              _btn('Refuser', DoctorColors.error, () async {
                setState(() => _busy = true);
                await widget.onCancel(appt['id'] as int? ?? 0);
              }),
            ] else
              _btn('Annuler', DoctorColors.error, () async {
                setState(() => _busy = true);
                await widget.onCancel(appt['id'] as int? ?? 0);
              }),
          ]),
        ]),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
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

// ── Patient access card ──────────────────────────────────────────────

class _PatientAccessCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onViewFile;
  const _PatientAccessCard({required this.patient, required this.onViewFile});

  @override
  Widget build(BuildContext context) {
    final user    = patient['user'] as Map<String, dynamic>? ?? {};
    final name    = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final email   = user['email'] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final blood   = patient['blood_type'] as String? ?? '--';
    final weight  = patient['weight']?.toString() ?? '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: DoctorColors.primary.withAlpha(18), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: DoctorColors.primaryLight,
          child: Text(initial, style: const TextStyle(color: DoctorColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isNotEmpty ? name : 'Patiente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: DoctorColors.textPrimary)),
          const SizedBox(height: 2),
          Text(email, style: const TextStyle(fontSize: 11, color: DoctorColors.textSecondary)),
          const SizedBox(height: 6),
          Row(children: [
            _chip(Iconsax.drop, blood, DoctorColors.error),
            const SizedBox(width: 6),
            _chip(Iconsax.weight, '$weight kg', DoctorColors.accent),
          ]),
        ])),
        IconButton(
          onPressed: onViewFile,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: DoctorColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Iconsax.document_text, color: DoctorColors.primary, size: 18),
          ),
          tooltip: 'Voir le dossier',
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── System alert card ────────────────────────────────────────────────

class _SystemAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onMarkRead;
  const _SystemAlertCard({required this.alert, required this.onMarkRead});

  IconData _icon(String level) {
    switch (level) {
      case 'CRITICAL': return Iconsax.danger;
      case 'WARNING':  return Iconsax.warning_2;
      default:         return Iconsax.info_circle;
    }
  }

  Color _color(String level) {
    switch (level) {
      case 'CRITICAL': return const Color(0xFFB71C1C);
      case 'WARNING':  return DoctorColors.warning;
      default:         return DoctorColors.primary;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'HEALTH':        return 'Santé';
      case 'REMINDER':      return 'Rappel';
      case 'DOCTOR_MESSAGE':return 'Message';
      case 'SYSTEM':        return 'Système';
      default:              return type;
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt  = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours   < 24) return 'Il y a ${diff.inHours} h';
      return 'Il y a ${diff.inDays} j';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final level  = alert['level']  as String? ?? 'INFO';
    final type   = alert['type']   as String? ?? 'SYSTEM';
    final msg    = alert['message']as String? ?? '';
    final status = alert['status'] as String? ?? 'NEW';
    final isNew  = status == 'NEW';
    final color  = _color(level);
    final time   = _timeAgo(alert['created_at'] as String?);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isNew ? color.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: isNew ? 4 : 2)),
        boxShadow: [BoxShadow(color: color.withAlpha(isNew ? 25 : 10), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(_icon(level), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                child: Text(_typeLabel(type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ),
              const Spacer(),
              if (time.isNotEmpty)
                Text(time, style: const TextStyle(fontSize: 10, color: DoctorColors.textLight)),
              if (isNew) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ]),
            const SizedBox(height: 6),
            Text(msg, style: const TextStyle(fontSize: 13, color: DoctorColors.textPrimary, height: 1.4)),
            if (isNew) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onMarkRead,
                child: Text('Marquer comme lu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, decoration: TextDecoration.underline)),
              ),
            ],
          ])),
        ]),
      ),
    );
  }
}
