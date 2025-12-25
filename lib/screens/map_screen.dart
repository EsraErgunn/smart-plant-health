import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../services/map_service.dart';
import '../services/geocoding_service.dart';
import '../services/permission_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService _mapService = MapService();

  late GoogleMapController _mapController;

  // Default position (Ankara)
  static const LatLng _initialPos = LatLng(39.9334, 32.8597);

  LatLng? _currentPos;

  // 🔹 Seçilen konum
  double? _selectedLat;
  double? _selectedLon;
  String _locationLabel = "Konum seçilmedi";

  // Marker’lar
  Set<Marker> _markers = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    final hasPermission = await PermissionService.requestLocation();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission required")),
        );
      }
      setState(() => _loading = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      _currentPos = LatLng(pos.latitude, pos.longitude);

      await _loadNearbyPlaces();
    } catch (e) {
      debugPrint("Location error: $e");
    }

    setState(() => _loading = false);
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentPos == null) return;

    final places = await _mapService.getNearbyPlaces(
      _currentPos!.latitude,
      _currentPos!.longitude,
    );

    _markers = places.map((place) {
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.lat, place.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          place.type == 'expert'
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueBlue,
        ),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.phone,
        ),
      );
    }).toSet();
  }

  /// 📍 Seçilen konuma haritayı götür
  void _moveMap(double lat, double lon) {
    _mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(lat, lon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _currentPos == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Experts & Stores"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _initialPos,
                zoom: 10,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,

              markers: {
                ..._markers,

                // 🔴 Seçilen konum marker’ı
                if (_selectedLat != null && _selectedLon != null)
                  Marker(
                    markerId: const MarkerId("selected_location"),
                    position: LatLng(_selectedLat!, _selectedLon!),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                  ),
              },

              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPos != null) {
                  controller.moveCamera(
                    CameraUpdate.newLatLngZoom(_currentPos!, 14),
                  );
                }
              },

              /// 🗺️ Haritaya tıklanınca
              onTap: (LatLng point) async {
                final address =
                    await GeocodingService.getAddressFromLatLng(
                  point.latitude,
                  point.longitude,
                );

                setState(() {
                  _selectedLat = point.latitude;
                  _selectedLon = point.longitude;
                  _locationLabel = address;
                });

                _moveMap(point.latitude, point.longitude);
              },
            ),
          ),

          /// 🏷️ Gerçek yer adı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: const Border(
                top: BorderSide(color: Colors.grey),
              ),
            ),
            child: Text(
              _locationLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
