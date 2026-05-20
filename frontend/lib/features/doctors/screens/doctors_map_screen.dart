import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class DoctorsMapScreen extends ConsumerStatefulWidget {
  const DoctorsMapScreen({super.key});

  @override
  ConsumerState<DoctorsMapScreen> createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends ConsumerState<DoctorsMapScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _selectedDoctor;
  final MapController _mapController = MapController();

  // Tunisia center
  static const LatLng _tunisiaCenter = LatLng(33.8869, 9.5375);

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load all doctors — we need all pages to show on map
      List<Map<String, dynamic>> all = [];
      String? nextUrl;
      final svc = ref.read(doctorServiceProvider);

      // First page
      final res = await svc.getAllDoctors();
      if (res['success'] == true) {
        final list = (res['doctors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        // Accept latitude as String (Decimal from Django) or num
        all.addAll(list.where((d) {
          final lat = d['latitude'];
          final lng = d['longitude'];
          if (lat == null || lng == null) return false;
          final latD = lat is num ? lat.toDouble() : double.tryParse('$lat');
          final lngD = lng is num ? lng.toDouble() : double.tryParse('$lng');
          return latD != null && lngD != null && !(latD == 0.0 && lngD == 0.0);
        }));
        nextUrl = res['next'] as String?;
      } else {
        // API returned error, show error state
        setState(() { _error = res['message']?.toString() ?? 'Erreur de chargement'; _loading = false; });
        return;
      }

      // Fetch remaining pages
      while (nextUrl != null && nextUrl.isNotEmpty) {
        final paged = await svc.getDoctorsByUrl(nextUrl);
        if (paged['success'] == true) {
          final list = (paged['doctors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          all.addAll(list.where((d) {
            final lat = d['latitude'];
            final lng = d['longitude'];
            if (lat == null || lng == null) return false;
            final latD = lat is num ? lat.toDouble() : double.tryParse('$lat');
            final lngD = lng is num ? lng.toDouble() : double.tryParse('$lng');
            return latD != null && lngD != null && !(latD == 0.0 && lngD == 0.0);
          }));
          nextUrl = paged['next'] as String?;
        } else {
          break;
        }
      }

      setState(() { _doctors = all; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Erreur de chargement: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          _buildMap(),

          // Top bar
          _buildTopBar(context),

          // Doctor info card (bottom)
          if (_selectedDoctor != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _DoctorMapCard(
                doctor: _selectedDoctor!,
                onClose: () => setState(() => _selectedDoctor = null),
                onDetail: () => context.push('/doctors/${_selectedDoctor!['id']}'),
              ).animate().slideY(begin: 0.4, duration: 300.ms).fadeIn(),
            ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),

          // No doctors with location
          if (!_loading && _doctors.isEmpty && _error == null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Iconsax.location_slash, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Aucun médecin localisé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Les médecins n\'ont pas encore partagé leur localisation.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _tunisiaCenter,
        initialZoom: 6.5,
        onTap: (_, __) => setState(() => _selectedDoctor = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.sahhty',
        ),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    return _doctors.map((doc) {
      final latRaw = doc['latitude'];
      final lngRaw = doc['longitude'];
      final lat = latRaw is num ? latRaw.toDouble() : double.tryParse('$latRaw') ?? 0.0;
      final lng = lngRaw is num ? lngRaw.toDouble() : double.tryParse('$lngRaw') ?? 0.0;
      if (lat == 0.0 && lng == 0.0) return null;

      final isSelected = _selectedDoctor?['id'] == doc['id'];

      return Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 56 : 46,
        height: isSelected ? 56 : 46,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedDoctor = doc);
            _mapController.move(LatLng(lat, lng), 14);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: isSelected ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(isSelected ? 100 : 50),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              Iconsax.hospital,
              color: isSelected ? Colors.white : AppColors.primary,
              size: isSelected ? 24 : 20,
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            // Back button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: IconButton(
                icon: const Icon(Iconsax.arrow_left, size: 22),
                onPressed: () => context.pop(),
              ),
            ),
            const SizedBox(width: 12),
            // Title card
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.location, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_doctors.length} médecin${_doctors.length > 1 ? 's' : ''} localisé${_doctors.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Refresh
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: IconButton(
                icon: const Icon(Iconsax.refresh_2, size: 20, color: AppColors.primary),
                onPressed: _loadDoctors,
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: -0.3, duration: 400.ms).fadeIn(),
    );
  }
}

// ── Doctor card shown at bottom when marker is tapped ─────────────────
class _DoctorMapCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onClose;
  final VoidCallback onDetail;

  const _DoctorMapCard({
    required this.doctor,
    required this.onClose,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = doctor['first_name'] ?? '';
    final lastName  = doctor['last_name']  ?? '';
    final name      = 'Dr. $firstName $lastName'.trim();
    final specialty = doctor['speciality'] is Map
        ? (doctor['speciality']['name'] ?? '')
        : (doctor['speciality'] ?? '');
    final ville     = doctor['ville'] ?? '';
    final price     = doctor['consultation_price'];
    final priceStr  = price != null ? '${price} TND' : 'N/A';
    final initial   = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withAlpha(30),
                  child: Text(initial, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (specialty.isNotEmpty)
                        Text(specialty, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 22, color: Colors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _infoChip(Iconsax.location, ville),
                const SizedBox(width: 8),
                _infoChip(Iconsax.money, priceStr),
              ],
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Iconsax.user, size: 16),
                label: const Text('Voir le profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onDetail,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
