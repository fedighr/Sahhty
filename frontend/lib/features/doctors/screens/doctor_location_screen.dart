import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:sahhty/data/providers/service_providers.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/features/home/screens/doctor_home_screen.dart';

class DoctorLocationScreen extends ConsumerStatefulWidget {
  const DoctorLocationScreen({super.key});

  @override
  ConsumerState<DoctorLocationScreen> createState() =>
      _DoctorLocationScreenState();
}

class _DoctorLocationScreenState extends ConsumerState<DoctorLocationScreen> {
  LatLng? _selectedLocation;
  bool _saving = false;
  bool _locating = false;
  final MapController _mapController = MapController();

  // Tunisia center
  static const LatLng _default = LatLng(33.8869, 9.5375);

  @override
  void initState() {
    super.initState();
    _loadExistingLocation();
  }

  Future<void> _loadExistingLocation() async {
    final auth = ref.read(authProvider);
    final doctorId = int.tryParse(auth.doctorId ?? '') ?? 0;
    if (doctorId == 0) return;

    try {
      // getAllDoctors returns latitude/longitude — filter by current doctor id
      final res = await ref.read(doctorServiceProvider).getAllDoctors();
      if (res['success'] == true) {
        final list = (res['doctors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final doc = list.firstWhere(
          (d) => d['id'] == doctorId,
          orElse: () => {},
        );
        if (doc.isNotEmpty) {
          final latRaw = doc['latitude'];
          final lngRaw = doc['longitude'];
          final lat = latRaw is num ? latRaw.toDouble() : double.tryParse('$latRaw');
          final lng = lngRaw is num ? lngRaw.toDouble() : double.tryParse('$lngRaw');
          if (lat != null && lng != null && lat != 0 && lng != 0) {
            final loc = LatLng(lat, lng);
            setState(() => _selectedLocation = loc);
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _mapController.move(loc, 14);
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _detectMyLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Activez la localisation sur votre appareil', error: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showSnack('Permission de localisation refusée', error: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _selectedLocation = loc);
      _mapController.move(loc, 16);
    } catch (e) {
      _showSnack('Impossible de détecter votre position', error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) {
      _showSnack('Sélectionnez une position sur la carte', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = ref.read(authProvider);
      final doctorId = int.tryParse(auth.doctorId ?? '') ?? 0;
      if (doctorId == 0) throw Exception('Doctor ID manquant');

      await ref.read(doctorServiceProvider).updateDoctorLocation(
        doctorId,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      _showSnack('Localisation enregistrée avec succès !');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Erreur lors de la sauvegarde', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? const Color(0xFFB71C1C) : DoctorColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _default,
              initialZoom: _selectedLocation != null ? 14.0 : 6.5,
              onTap: (_, latlng) {
                setState(() => _selectedLocation = latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sahhty',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 60,
                        height: 70,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: DoctorColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: DoctorColors.primary.withAlpha(100), blurRadius: 12, spreadRadius: 2),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(Iconsax.hospital, color: Colors.white, size: 20),
                            ),
                            const Icon(Icons.arrow_drop_down, color: DoctorColors.primary, size: 24),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Back
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                        ),
                        child: IconButton(
                          icon: const Icon(Iconsax.arrow_left, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                          ),
                          child: const Row(
                            children: [
                              Icon(Iconsax.location, color: DoctorColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Ma localisation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Hint card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: const Row(
                      children: [
                        Icon(Iconsax.info_circle, size: 16, color: DoctorColors.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Appuyez sur la carte pour placer votre cabinet',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().slideY(begin: -0.3, duration: 400.ms).fadeIn(),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Selected coords
                if (_selectedLocation != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.location_tick, size: 16, color: DoctorColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.3, duration: 300.ms).fadeIn(),

                Row(
                  children: [
                    // Detect location
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _locating
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Iconsax.gps, size: 16),
                        label: Text(_locating ? '...' : 'Ma position'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: DoctorColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: DoctorColors.primary)),
                          elevation: 4,
                        ),
                        onPressed: _locating ? null : _detectMyLocation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: _saving
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Iconsax.tick_circle, size: 16),
                        label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoctorColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        onPressed: _saving ? null : _saveLocation,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().slideY(begin: 0.4, duration: 400.ms).fadeIn(),
          ),
        ],
      ),
    );
  }
}

