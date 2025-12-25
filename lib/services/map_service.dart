import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapService {
  static final String? _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']; 
  
  // Use a generic global query for text search
  static const String _defaultQuery = 'agricultural dealers, zirai ilaç bayileri';

  Future<List<PlaceModel>> searchDealers(
    double lat,
    double lng, {
    String? query,
  }) async {
    if (_apiKey == null) {
      debugPrint("GOOGLE_MAPS_API_KEY is missing");
      return [];
    }
    
    // Combining generic terms if no specific query is passed
    final String effectiveQuery = query ?? _defaultQuery;

    // Google Maps Text Search API
    // We pass location to bias results, but NO radius to allow "Turkey-wide" or broader results if local ones aren't found.
    final url =
        'https://maps.googleapis.com/maps/api/place/textsearch/json'
        '?query=${Uri.encodeComponent(effectiveQuery)}'
        '&location=$lat,$lng'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
           List<PlaceModel> places = [];
           for (var item in data['results']) {
             places.add(
               PlaceModel(
                 name: item['name'],
                 lat: item['geometry']['location']['lat'],
                 lng: item['geometry']['location']['lng'],
                 rating: (item['rating'] ?? 0).toDouble(),
                 isOpen: item['opening_hours']?['open_now'] ?? false,
               ),
             );
           }
           return places;
        } else {
           debugPrint('Places API status: ${data['status']}');
        }
      }
    } catch (e) {
      debugPrint('Error fetching text search: $e');
    }
    
    return [];
  }

  // Kept for backward compatibility if needed, but redirects to search
  Future<List<PlaceModel>> getNearbyAgroDealers(double lat, double lng) async {
    return searchDealers(lat, lng);
  }
}
