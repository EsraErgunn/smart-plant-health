import '../models/place_model.dart';
import 'dart:math';

class MapService {
  // Mock data generator for nearby places
  Future<List<Place>> getNearbyPlaces(double lat, double lng) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    
    final Random random = Random();
    List<Place> places = [];

    // Generate 3 experts
    for (int i = 0; i < 3; i++) {
        double offsetLat = (random.nextDouble() - 0.5) * 0.02; // Roughly 2km
        double offsetLng = (random.nextDouble() - 0.5) * 0.02;
        
        places.add(Place(
            id: 'expert_$i',
            name: 'Expert Agronomist ${String.fromCharCode(65+i)}',
            type: 'expert',
            lat: lat + offsetLat,
            lng: lng + offsetLng,
            address: 'Agricultural Zone ${i+1}',
            phone: '+1 555 010 $i'
        ));
    }

    // Generate 2 stores
    for (int i = 0; i < 2; i++) {
        double offsetLat = (random.nextDouble() - 0.5) * 0.02;
        double offsetLng = (random.nextDouble() - 0.5) * 0.02;
        
        places.add(Place(
            id: 'store_$i',
            name: 'Farm Supply Store ${i+1}',
            type: 'store',
            lat: lat + offsetLat,
            lng: lng + offsetLng,
            address: 'Market Street ${i+10}',
            phone: '+1 555 020 $i'
        ));
    }

    return places;
  }
}
