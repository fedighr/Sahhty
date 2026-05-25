import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/core/widgets/floating_particles.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class DoctorsListScreen extends ConsumerStatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  ConsumerState<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends ConsumerState<DoctorsListScreen>
    with TickerProviderStateMixin {
  List<dynamic> _doctors = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String? _selectedVille;

  static const _tunisianCities = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'El Kef', 'Siliana', 'Sousse',
    'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili',
  ];
  Timer? _debounce;
  String _selectedFilter = 'Tous';
  String _selectedGender = 'Tous'; // 'Tous', 'M', 'F'
  bool _sortByProximity = false;
  bool _gettingLocation = false;
  double? _userLat;
  double? _userLon;
  late AnimationController _headerAnim;

  // Dynamic specialities from backend
  List<String> _specialities = ['Tous'];

  // Pagination state
  int _currentPage = 1;
  int _totalCount = 0;
  String? _nextUrl;
  String? _prevUrl;
  bool _isSearchMode = false;

  int get _totalPages => _totalCount == 0 ? 1 : ((_totalCount + 7) ~/ 8).clamp(1, 9999);

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _headerAnim.forward();
    _loadSpecialities();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialities() async {
    final result = await ref.read(doctorServiceProvider).getSpecialities();
    if (!mounted) return;
    if (result['success'] == true) {
      final list = (result['specialities'] as List?)?.map((s) => s['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList() ?? [];
      setState(() {
        _specialities = ['Tous', ...list];
      });
    }
  }

  Future<void> _loadDoctors() async {
    setState(() { _loading = true; _error = null; _isSearchMode = false; });
    final speciality = _selectedFilter == 'Tous' ? null : _selectedFilter;
    final gender = _selectedGender == 'Tous' ? null : _selectedGender;
    final ville = _selectedVille;
    final result = await ref.read(doctorServiceProvider).getAllDoctors(
      speciality: speciality,
      gender: gender,
      ville: ville,
      latitude: _sortByProximity ? _userLat : null,
      longitude: _sortByProximity ? _userLon : null,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _doctors = result['doctors'] ?? [];
        _totalCount = result['count'] ?? _doctors.length;
        _nextUrl = result['next'];
        _prevUrl = result['previous'];
        _currentPage = 1;
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }


  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() { _isSearchMode = false; _currentPage = 1; });
      _loadDoctors();
      return;
    }
    if (query.length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() { _loading = true; _error = null; _isSearchMode = true; });
      final result = await ref.read(doctorServiceProvider).searchDoctors(query);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result['success'] == true) {
          _doctors = result['doctors'] ?? [];
          _totalCount = result['count'] ?? _doctors.length;
          _nextUrl = result['next'];
          _prevUrl = result['previous'];
          _currentPage = 1;
        } else if (result.containsKey('detail')) {
          _doctors = [];
          _totalCount = 0;
          _nextUrl = null;
          _prevUrl = null;
        } else {
          _error = result['message'] ?? 'Erreur';
        }
      });
    });
  }

  Future<void> _searchPage(String? url) async {
    if (url == null) return;
    setState(() => _loading = true);
    final result = await ref.read(doctorServiceProvider).getDoctorsByUrl(url);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _doctors = result['doctors'] ?? [];
        _totalCount = result['count'] ?? _doctors.length;
        _nextUrl = result['next'];
        _prevUrl = result['previous'];
        if (_prevUrl == null) _currentPage = 1;
        else if (_nextUrl == null) _currentPage = _totalPages;
        else _currentPage = _prevUrl == null ? 1 : _currentPage;
      }
    });
  }

  void _goToPage(int page) {
    if (!_isSearchMode) {
      // For non-search mode, each page navigates using URL from backend
      setState(() { _currentPage = page; });
    }
  }

  Future<void> _toggleProximity() async {
    if (_sortByProximity) {
      setState(() { _sortByProximity = false; _userLat = null; _userLon = null; });
      _loadDoctors();
      return;
    }
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez activer la localisation')));
        }
        setState(() => _gettingLocation = false);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de localisation refusée')));
        }
        setState(() => _gettingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      setState(() {
        _userLat = pos.latitude;
        _userLon = pos.longitude;
        _sortByProximity = true;
        _gettingLocation = false;
      });
      _loadDoctors();
    } catch (e) {
      setState(() => _gettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de localisation: $e')));
      }
    }
  }

  void _onGenderChanged(String gender) {
    if (_selectedGender == gender) return;
    setState(() { _selectedGender = gender; });
    _loadDoctors();
  }


  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _searchCtrl.clear();
      _isSearchMode = false;
    });
    _loadDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false, imageOpacity: 0),
          const FloatingParticles(particleCount: 6, maxOpacity: 0.05),
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildSearchAndFilter()),
              _loading
                  ? const SliverToBoxAdapter(
                      child: SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.primary))))
                  : _error != null
                      ? SliverToBoxAdapter(child: _buildError())
                      : _doctors.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmpty())
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => _DoctorCard(
                                    doctor: _doctors[i],
                                    index: i,
                                    onTap: () => context.push('/doctors/${_doctors[i]['id']}', extra: _doctors[i]),
                                  ).animate().fadeIn(delay: (60 * i).ms).slideX(begin: 0.06),
                                  childCount: _doctors.length,
                                ),
                              ),
                            ),
              if (!_loading && _error == null && _totalPages > 1)
                SliverToBoxAdapter(child: _buildPagination()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _PaginationButton(
            icon: Iconsax.arrow_left_2,
            label: 'Précédent',
            enabled: _isSearchMode ? _prevUrl != null : _currentPage > 1,
            onTap: () {
              if (_isSearchMode) {
                _currentPage--;
                _searchPage(_prevUrl);
              } else {
                _goToPage(_currentPage - 1);
              }
            },
          ),
          const SizedBox(width: 12),
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Text(
              'Page $_currentPage / $_totalPages',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          // Next button
          _PaginationButton(
            icon: Iconsax.arrow_right_3,
            label: 'Suivant',
            enabled: _isSearchMode ? _nextUrl != null : _currentPage < _totalPages,
            onTap: () {
              if (_isSearchMode) {
                _currentPage++;
                _searchPage(_nextUrl);
              } else {
                _goToPage(_currentPage + 1);
              }
            },
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildSliverAppBar() {
    final total = _totalCount;
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
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF80CBC4), Color(0xFF4DB6AC), Color(0xFFB2DFDB)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
                        child: const Icon(Iconsax.hospital, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trouver un médecin',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('$total médecin${total > 1 ? 's' : ''} disponible${total > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      )),
                      // Map view button
                      GestureDetector(
                        onTap: () => context.push('/doctors/map'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(100)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.location, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Carte', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate(controller: _headerAnim).fadeIn().slideX(begin: -0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, spécialité...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(Iconsax.search_normal, color: AppColors.accent, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle, size: 18, color: AppColors.textSecondary),
                        onPressed: () { _searchCtrl.clear(); _loadDoctors(); },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Ville dropdown
          GestureDetector(
            onTap: () async {
              final selected = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _CityPickerSheet(
                  cities: _tunisianCities,
                  selected: _selectedVille,
                ),
              );
              if (selected != null) {
                setState(() => _selectedVille = selected == '' ? null : selected);
                _loadDoctors();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Iconsax.location, color: AppColors.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedVille ?? 'Filtrer par ville...',
                      style: TextStyle(
                        color: _selectedVille != null ? AppColors.textPrimary : AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_selectedVille != null)
                    GestureDetector(
                      onTap: () { setState(() => _selectedVille = null); _loadDoctors(); },
                      child: const Icon(Iconsax.close_circle, size: 18, color: AppColors.textSecondary),
                    )
                  else
                    const Icon(Iconsax.arrow_down, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Gender + Proximity row
          Row(
            children: [
              // Gender chips
              const Text('Genre :', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ...[('Tous', null), ('H', 'M'), ('F', 'F')].map((entry) {
                final label = entry.$1;
                final value = entry.$2 ?? 'Tous';
                final selected = _selectedGender == value;
                return GestureDetector(
                  onTap: () => _onGenderChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.accent : const Color(0xFFE0E0E0)),
                    ),
                    child: Text(label, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    )),
                  ),
                );
              }),
              const Spacer(),
              // Proximity toggle
              GestureDetector(
                onTap: _gettingLocation ? null : _toggleProximity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _sortByProximity ? AppColors.accent : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _sortByProximity ? AppColors.accent : const Color(0xFFE0E0E0)),
                    boxShadow: _sortByProximity
                        ? [BoxShadow(color: AppColors.accent.withAlpha(60), blurRadius: 8)]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_gettingLocation)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      else
                        Icon(Iconsax.location_tick, size: 14,
                            color: _sortByProximity ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text('Proximité', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: _sortByProximity ? Colors.white : AppColors.textSecondary,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Speciality chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _specialities.length,
              itemBuilder: (_, i) {
                final f = _specialities[i];
                final selected = _selectedFilter == f;
                return GestureDetector(
                  onTap: () => _onFilterChanged(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.accent : const Color(0xFFE0E0E0)),
                      boxShadow: selected ? [BoxShadow(color: AppColors.accent.withAlpha(60), blurRadius: 8)] : [],
                    ),
                    child: Text(f, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    )),
                  ),
                );
              },
            ),
          ),
          // Results count
          if (!_loading && _error == null && _totalCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Iconsax.user, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _isSearchMode
                        ? '$_totalCount résultat${_totalCount > 1 ? 's' : ''} trouvé${_totalCount > 1 ? 's' : ''}'
                        : 'Page $_currentPage sur $_totalPages · $_totalCount médecin${_totalCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (_sortByProximity) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.location_tick, size: 11, color: AppColors.accent),
                          SizedBox(width: 3),
                          Text('Triés par proximité', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.error.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Iconsax.close_circle, size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: _loadDoctors,
          icon: const Icon(Iconsax.refresh_2, size: 18), label: const Text('Réessayer')),
      ]).animate().fadeIn(),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent.withAlpha(40), AppColors.accent.withAlpha(20)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.hospital, size: 48, color: AppColors.accent),
        ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text('Aucun médecin trouvé',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Essayez de modifier votre recherche',
          style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]).animate().fadeIn(),
    );
  }
}

// ── Pagination Button Widget ──────────────────────────────────────────────────
class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? AppColors.accent.withAlpha(100) : Colors.grey.shade300,
          ),
          boxShadow: enabled
              ? [BoxShadow(color: AppColors.accent.withAlpha(30), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == Iconsax.arrow_left_2) ...[
              Icon(icon, size: 16, color: enabled ? AppColors.accent : Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: enabled ? AppColors.accent : Colors.grey.shade400,
              )),
            ] else ...[
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: enabled ? AppColors.accent : Colors.grey.shade400,
              )),
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: enabled ? AppColors.accent : Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Doctor Card ───────────────────────────────────────────────────────────────
class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final int index;
  final VoidCallback onTap;
  const _DoctorCard({required this.doctor, required this.index, required this.onTap});

  static const _avatarGradients = [
    [Color(0xFFFF8FA3), Color(0xFFFFB3C1)],
    [Color(0xFF80CBC4), Color(0xFFB2DFDB)],
    [Color(0xFFCE93D8), Color(0xFFE1BEE7)],
    [Color(0xFFFFCC80), Color(0xFFFFE0B2)],
    [Color(0xFF90CAF9), Color(0xFFBBDEFB)],
  ];

  @override
  Widget build(BuildContext context) {
    final isNested = doctor.containsKey('user') && doctor['user'] is Map;
    final firstName = isNested ? (doctor['user']['first_name'] ?? '') : (doctor['first_name'] ?? '');
    final lastName = isNested ? (doctor['user']['last_name'] ?? '') : (doctor['last_name'] ?? '');
    final name = 'Dr. $firstName $lastName';
    final specObj = doctor['speciality'];
    final spec = specObj is Map ? (specObj['name'] ?? 'Non spécifié') : (specObj?.toString() ?? 'Non spécifié');
    final ville = doctor['ville'] ?? '';
    final experience = doctor['experience'];
    final price = doctor['consultation_price'];

    final grad = _avatarGradients[index % _avatarGradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: grad[0].withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with gradient
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Icon(Iconsax.user, size: 30, color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: grad[0].withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(spec, style: TextStyle(color: grad[0], fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      children: [
                        if (ville.toString().isNotEmpty)
                          _miniInfo(Iconsax.location, ville.toString()),
                        if (experience != null)
                          _miniInfo(Iconsax.briefcase, '$experience ans'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: grad[0].withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Iconsax.arrow_right_3, size: 16, color: grad[0]),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 6),
                    Text('$price DT',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textSecondary),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

// ── City Picker Bottom Sheet ──────────────────────────────────────────────────
class _CityPickerSheet extends StatefulWidget {
  final List<String> cities;
  final String? selected;
  const _CityPickerSheet({required this.cities, this.selected});

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _ctrl = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.cities;
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? widget.cities
          : widget.cities.where((c) => c.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Iconsax.location, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text('Choisir une ville',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const Spacer(),
                if (widget.selected != null)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, ''),
                    child: const Text('Effacer', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              onChanged: _onSearch,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Rechercher une ville...',
                prefixIcon: const Icon(Iconsax.search_normal, color: AppColors.textLight, size: 18),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final city = _filtered[i];
                final isSelected = city == widget.selected;
                return ListTile(
                  leading: Icon(
                    Iconsax.location,
                    size: 18,
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                  ),
                  title: Text(city,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      )),
                  trailing: isSelected
                      ? const Icon(Iconsax.tick_circle, color: AppColors.accent, size: 20)
                      : null,
                  onTap: () => Navigator.pop(context, city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

