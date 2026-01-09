import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../services/map_service.dart';
import '../services/disease_filter.dart';
import '../models/place_model.dart';
import 'dart:async';

class MapController extends ChangeNotifier {
  final MapService _mapService = MapService();
  
  Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoading = false; 
  String? _errorMessage;
  GoogleMapController? _mapController;
  
  PlaceModel? _selectedPlace; // Currently selected dealer
  
  // Data about the context
  String _targetDisease = '';
  String _recommendedMedicine = '';
  
  // Track camera center for dynamic updates
  LatLng? _lastCameraCenter;
  Timer? _debounceTimer;

  Set<Marker> get markers => _markers;
  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get targetDisease => _targetDisease;
  String get recommendedMedicine => _recommendedMedicine;
  PlaceModel? get selectedPlace => _selectedPlace;

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  void onCameraMove(CameraPosition position) {
    _lastCameraCenter = position.target;
  }
  
  void onCameraIdle() {
    if (_lastCameraCenter != null) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(seconds: 1), () {
        _searchInArea(_lastCameraCenter!);
      });
    }
  }

  void selectPlace(PlaceModel place) {
    _selectedPlace = place;
    _moveCamera(LatLng(place.lat, place.lng));
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedPlace = null;
    notifyListeners();
  }

  Future<void> launchDirections(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'
    );
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      _errorMessage = "Could not launch maps";
      notifyListeners();
    }
  }

  // Hedef hastalık belirlenir ,Önerilen ilaç tipi hesaplanır, Kullanıcının GPS konumu alınır,
  //Harita oraya gider,Bayiler aranır,Marker’lar basılır
  Future<void> loadCurrentLocationAndDealers(String diseaseName) async {
    _targetDisease = diseaseName;
    _recommendedMedicine = DiseaseFilter.getRequiredMedicineType(diseaseName);
    
    _isLoading = true;
    notifyListeners();

    try {
      final position = await _determinePosition();
      _currentPosition = LatLng(position.latitude, position.longitude);
      _lastCameraCenter = _currentPosition;
      
      if (_mapController != null) {
        _moveCamera(_currentPosition!);
      }
      
      await _performSearch(position.latitude, position.longitude);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // seçildiği yere göre haritanın güncellenmesi için yaptım
  Future<void> updateManualLocation(double lat, double lng) async {
    _currentPosition = LatLng(lat, lng);
    _lastCameraCenter = _currentPosition;
    _isLoading = true;
    notifyListeners();

    try {
      if (_mapController != null) {
         _moveCamera(_currentPosition!);
      }
      
      await _performSearch(lat, lng);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> _searchInArea(LatLng center) async {
    await _performSearch(center.latitude, center.longitude);
    notifyListeners();
  }

  Future<void> _performSearch(double lat, double lng) async {
    try {
      final places = await _mapService.searchDealers(lat, lng);
      _makeMarkers(places);
    } catch (e) {
      debugPrint("Search failed: $e");
    }
  }
// marker üretimi
  void _makeMarkers(List<PlaceModel> places) {
    _markers = places.map((place) {
      return Marker(
        markerId: MarkerId(place.name),
        position: LatLng(place.lat, place.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onTap: () {
          selectPlace(place);
        },
      );
    }).toSet();
  }

  void _moveCamera(LatLng pos) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(pos, 12), 
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
