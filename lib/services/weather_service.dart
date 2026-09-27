import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../config/env.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// 🌦️ Anlık hava durumu
  Future<WeatherData?> getCurrentWeather(double lat, double lon) async {
    const apiKey = Env.openWeatherKey;

    // ✅ DOĞRU API KEY KONTROLÜ
    if (apiKey.isEmpty) {
      debugPrint("⚠️ OpenWeather API Key missing");
      return null;
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return WeatherData.fromJson(json.decode(response.body));
      } else {
        debugPrint(
          "❌ Weather API error | status: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("❌ Error fetching current weather: $e");
    }

    return null;
  }

  /// 📅 5 günlük tahmin (günde 1 veri)
  Future<List<ForecastData>> getForecast(double lat, double lon) async {
    const apiKey = Env.openWeatherKey;

    // ✅ DOĞRU API KEY KONTROLÜ
    if (apiKey.isEmpty) {
      debugPrint("⚠️ OpenWeather API Key missing");
      return [];
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['list'];

        // ⏱️ 3 saatlik verilerden günde 1 tane al
        List<ForecastData> forecasts = [];
        for (int i = 0; i < list.length; i += 8) {
          forecasts.add(ForecastData.fromJson(list[i]));
        }

        return forecasts;
      } else {
        debugPrint(
          "❌ Forecast API error | status: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("❌ Error fetching forecast: $e");
    }

    return [];
  }
}
