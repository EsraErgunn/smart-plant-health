import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../config/env.dart';
import '../models/city_model.dart';

class GeocodingService {
  static const _baseUrl =
      'https://api.openweathermap.org/geo/1.0/direct';

  ///  Şehir adına göre arama (Forward Geocoding)
  Future<List<City>> searchCity(String query) async {
    const apiKey = Env.openWeatherKey;

    if (apiKey.isEmpty) {
      throw Exception("OpenWeather API Key missing");
    }

    final q = Uri.encodeComponent("${query.trim()},TR");

    final url = '$_baseUrl?q=$q&limit=10&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      if (data.isEmpty) return [];

      return data.map((e) => City.fromJson(e)).toList();
    } else {
      throw Exception("Geocoding failed");
    }
  }

  ///  Koordinattan gerçek adres alma ksımı (Reverse Geocoding)
  static Future<String> getAddressFromLatLng(
      double lat, double lon) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(lat, lon);

      if (placemarks.isEmpty) return "Bilinmeyen Konum";

      final p = placemarks.first;

      final city = p.locality ?? p.administrativeArea ?? '';
      final district = p.subAdministrativeArea ?? '';
      final country = p.country ?? '';

      return [
        if (city.isNotEmpty) city,
        if (district.isNotEmpty) district,
        if (country.isNotEmpty) country,
      ].join(", ");
    } catch (e) {
      return "Adres bulunamadı";
    }
  }
}
