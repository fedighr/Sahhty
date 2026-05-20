import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final int doctorId;
  final Map<String, dynamic>? initialData;
  const DoctorDetailScreen({super.key, required this.doctorId, this.initialData});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _doctor;
  List<dynamic> _schedule = [];
  List<String> _availableSlots = [];
  DateTime? _selectedDate;
  String? _selectedSlot;
  bool _loadingDoctor = true;
  bool _loadingSlots = false;
  bool _booking = false;
  String? _error;
  late TabController _tabController;
  late AnimationController _heroAnim;

  static const _dayNames = {
    'MONDAY': 'Lundi', 'TUESDAY': 'Mardi', 'WEDNESDAY': 'Mercredi',
    'THURSDAY': 'Jeudi', 'FRIDAY': 'Vendredi', 'SATURDAY': 'Samedi', 'SUNDAY': 'Dimanche',
  };
  static const _dayEnglish = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];
  static const _dayShort = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _heroAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _heroAnim.forward();
    _loadDoctor();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroAnim.dispose();
    super.dispose();
  }

  Future<void> _loadDoctor() async {
    // Use initial data if available (flat dict from getAllDoctors)
    if (widget.initialData != null) {
      setState(() {
        _doctor = widget.initialData;
        _loadingDoctor = false;
      });
    } else {
      final result = await ref.read(doctorServiceProvider).getDoctorById(widget.doctorId);
      if (!mounted) return;
      setState(() {
        _loadingDoctor = false;
        if (result['success'] == true) _doctor = result['doctor'];
        else _error = result['message'];
      });
    }
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final result = await ref.read(doctorServiceProvider).getDoctorSchedule(widget.doctorId);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _schedule = result['schedules'] ?? []);
    }
  }

  Future<void> _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date; _selectedSlot = null;
      _loadingSlots = true; _availableSlots = [];
    });
    // weekday: 1=Monday…7=Sunday
    final dayStr = _dayEnglish[date.weekday - 1];
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final result = await ref.read(doctorServiceProvider).getDoctorAvailableSlots(widget.doctorId, dayStr, dateStr);
    if (!mounted) return;
    setState(() {
      _loadingSlots = false;
      if (result['success'] == true) {
        _availableSlots = List<String>.from(result['available_slots'] ?? []);
      }
    });
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedSlot == null) return;
    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) { _showSnack('ID patient non trouvé', isError: true); return; }

    // Build appointment_date from date + slot
    final parts = _selectedSlot!.split(':');
    final appointmentDate = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );

    setState(() => _booking = true);
    final result = await ref.read(appointmentServiceProvider).createAppointment({
      'patient_id': patientId,
      'doctor_id': widget.doctorId,
      'appointment_date': appointmentDate.toIso8601String(),
    });
    if (!mounted) return;
    setState(() => _booking = false);

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showSnack(result['message'] ?? 'Erreur', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Iconsax.close_circle : Iconsax.tick_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF43A047)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.success.withAlpha(60), blurRadius: 16)],
              ),
              child: const Icon(Iconsax.tick_circle, color: Colors.white, size: 40),
            ).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 20),
            const Text('Rendez-vous confirmé !',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (_selectedDate != null && _selectedSlot != null)
              Text(
                '${_dayNames[_dayEnglish[_selectedDate!.weekday - 1]]} ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} à $_selectedSlot',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.of(ctx).pop(); context.pop(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Parfait !', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _getDoctorName() {
    if (_doctor == null) return 'Dr.';
    final isNested = _doctor!.containsKey('user') && _doctor!['user'] is Map;
    final fn = isNested ? _doctor!['user']['first_name'] : _doctor!['first_name'];
    final ln = isNested ? _doctor!['user']['last_name'] : _doctor!['last_name'];
    return 'Dr. ${fn ?? ''} ${ln ?? ''}';
  }

  String _getSpeciality() {
    if (_doctor == null) return '';
    final s = _doctor!['speciality'];
    if (s is Map) return s['name'] ?? '';
    return s?.toString() ?? '';
  }

  int get _availableDaysCount => _schedule.where((s) => s['is_available'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loadingDoctor
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : Stack(
                  children: [
                    const AnimatedBackground(showImage: false, imageOpacity: 0),
                    CustomScrollView(
                      slivers: [
                        _buildHeroHeader(),
                        SliverToBoxAdapter(child: _buildStatsRow()),
                        SliverToBoxAdapter(child: _buildLocationSection()),
                        SliverToBoxAdapter(child: _buildTabBar()),
                        SliverToBoxAdapter(child: _buildTabContent()),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                    // Floating back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                        ),
                        child: IconButton(
                          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary, size: 22),
                          onPressed: () => context.pop(),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeroHeader() {
    final d = _doctor!;
    final spec = _getSpeciality();
    final bio = d['bio'] ?? '';
    final gradColors = [const Color(0xFF80CBC4), const Color(0xFF26A69A)];

    return SliverAppBar(
      expandedHeight: 280,
      pinned: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradColors,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Doctor avatar with glow
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(30),
                    border: Border.all(color: Colors.white.withAlpha(100), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: const Icon(Iconsax.user, size: 50, color: Colors.white),
                ).animate(controller: _heroAnim).scale(curve: Curves.elasticOut, delay: 100.ms),
                const SizedBox(height: 12),
                Text(_getDoctorName(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))
                    .animate(controller: _heroAnim).fadeIn(delay: 200.ms).slideY(begin: 0.2),
                if (spec.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(spec, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ).animate(controller: _heroAnim).fadeIn(delay: 300.ms),
                ],
                if (bio.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(bio.toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ).animate(controller: _heroAnim).fadeIn(delay: 400.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final d = _doctor!;
    final ville = d['ville']?.toString() ?? '';
    final experience = d['experience'];
    final price = d['consultation_price'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      transform: Matrix4.translationValues(0, -20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF80CBC4).withAlpha(40), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (experience != null) _statItem(Iconsax.briefcase, '$experience ans', 'Expérience'),
          if (price != null) _statItem(Iconsax.money_recive, '$price DT', 'Consultation'),
          _statItem(Iconsax.calendar_tick, '$_availableDaysCount j/sem', 'Disponible'),
          if (ville.isNotEmpty) _statItem(Iconsax.location, ville, 'Ville'),
        ].where((e) => true).toList(),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.accent),
      ),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildLocationSection() {
    final d = _doctor;
    if (d == null) return const SizedBox.shrink();

    final lat = double.tryParse('${d['latitude'] ?? ''}');
    final lng = double.tryParse('${d['longitude'] ?? ''}');
    final address = d['address']?.toString() ?? '';
    final ville = d['ville']?.toString() ?? '';

    if (lat == null || lng == null || lat == 0 || lng == 0) {
      // Show address only
      if (address.isEmpty && ville.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Row(children: [
          const Icon(Iconsax.location, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('$address${ville.isNotEmpty ? ', $ville' : ''}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ]),
      ).animate().fadeIn(delay: 450.ms);
    }

    final loc = LatLng(lat, lng);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(30), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              const Icon(Iconsax.location, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Localisation du cabinet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              if (address.isNotEmpty)
                Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: loc,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.sahhty',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: loc,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(100), blurRadius: 10, spreadRadius: 2)],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Iconsax.hospital, color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Iconsax.calendar_2, size: 18), text: 'Prendre RDV'),
          Tab(icon: Icon(Iconsax.clock, size: 18), text: 'Horaires'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? _buildBookingTab()
            : _buildScheduleTab(),
      ),
    );
  }

  Widget _buildBookingTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section titre
          _sectionTitle(Iconsax.calendar_1, 'Choisissez une date'),
          const SizedBox(height: 12),
          _buildDatePicker(),
          const SizedBox(height: 20),
          if (_loadingSlots)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ))
          else if (_selectedDate != null && _availableSlots.isEmpty)
            _buildNoSlots()
          else if (_availableSlots.isNotEmpty) ...[
            _sectionTitle(Iconsax.clock, 'Créneaux disponibles'),
            const SizedBox(height: 12),
            _buildSlotPicker(),
          ],
          if (_selectedSlot != null) ...[
            const SizedBox(height: 24),
            _buildBookButton(),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    ]);
  }

  Widget _buildDatePicker() {
    final now = DateTime.now();
    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, i) {
          final date = now.add(Duration(days: i + 1));
          final isSelected = _selectedDate != null &&
              _selectedDate!.day == date.day && _selectedDate!.month == date.month;
          final dayStr = _dayEnglish[date.weekday - 1];
          final hasSchedule = _schedule.any((s) => s['day_of_week'] == dayStr && s['is_available'] == true);

          return GestureDetector(
            onTap: hasSchedule ? () => _onDateSelected(date) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 62,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isSelected ? null : (hasSchedule ? Colors.white : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 4)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_dayShort[date.weekday - 1],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : (hasSchedule ? AppColors.textSecondary : Colors.grey.shade400))),
                  const SizedBox(height: 4),
                  Text('${date.day}', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (hasSchedule ? AppColors.textPrimary : Colors.grey.shade400))),
                  const SizedBox(height: 2),
                  if (hasSchedule && !isSelected)
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNoSlots() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Row(children: [
        const Icon(Iconsax.calendar_remove, color: AppColors.warning, size: 24),
        const SizedBox(width: 12),
        const Expanded(child: Text('Aucun créneau disponible ce jour-là',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
      ]),
    );
  }

  Widget _buildSlotPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _availableSlots.map((slot) {
        final selected = slot == _selectedSlot;
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
              boxShadow: selected
                  ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                  : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Iconsax.clock, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(slot, style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600, fontSize: 14,
              )),
            ]),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(80), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _booking ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _booking
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Iconsax.calendar_tick, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text('Confirmer le rendez-vous',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }

  Widget _buildScheduleTab() {
    if (_schedule.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), shape: BoxShape.circle),
            child: const Icon(Iconsax.clock, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Horaires non disponibles', style: TextStyle(color: AppColors.textSecondary)),
        ]).animate().fadeIn(),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: _schedule.map((s) {
          final day = _dayNames[s['day_of_week']] ?? s['day_of_week'];
          final available = s['is_available'] == true;
          final start = available ? (s['start_time'] ?? '').toString().substring(0, 5) : '';
          final end = available ? (s['end_time'] ?? '').toString().substring(0, 5) : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: available ? Colors.white : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: available ? AppColors.accent.withAlpha(60) : Colors.grey.shade200,
              ),
              boxShadow: available
                  ? [BoxShadow(color: AppColors.accent.withAlpha(20), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: available ? AppColors.accent.withAlpha(25) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(available ? Iconsax.clock : Iconsax.close_circle,
                  size: 18, color: available ? AppColors.accent : Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(day.toString(),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                  color: available ? AppColors.textPrimary : AppColors.textSecondary))),
              if (available)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$start – $end',
                    style: const TextStyle(color: AppColors.accentDark, fontWeight: FontWeight.w600, fontSize: 13)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Fermé',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13)),
                ),
            ]),
          ).animate().fadeIn(delay: (50 * _schedule.indexOf(s)).ms).slideX(begin: 0.05);
        }).toList(),
      ),
    );
  }
}
