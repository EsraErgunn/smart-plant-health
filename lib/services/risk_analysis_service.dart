import '../models/weather_model.dart';
import '../models/risk_explanation.dart';
import '../models/plant_type.dart';
import 'plant_risk_service.dart';

class RiskAlert {
  final String title;
  final String message;
  final String severity; // High, Medium, Low

  RiskAlert({
    required this.title,
    required this.message,
    required this.severity,
  });
}

class RiskAnalysisService {
  // ===============================
  // 🔢 SCORE CALCULATION HELPERS
  // ===============================

  int humidityScore(int humidity) {
    if (humidity >= 85) return 40;
    if (humidity >= 75) return 30;
    if (humidity >= 65) return 20;
    if (humidity >= 55) return 10;
    return 0;
  }

  int rainScore(bool rainExpected) {
    return rainExpected ? 30 : 0;
  }

  int temperatureScore(double temp) {
    if (temp >= 18 && temp <= 28) return 30; // fungal ideal
    if (temp >= 15 && temp <= 32) return 15;
    return 0;
  }

  // ===============================
  // 🌡️ BASE RISK SCORE (0–100)
  // ===============================
  int calculateRiskScore(
    WeatherData current,
    List<ForecastData> forecast,
  ) {
    final bool rainExpected = forecast.any(
      (f) => f.description.toLowerCase().contains("rain"),
    );

    final int score =
        humidityScore(current.humidity.toInt()) +
        temperatureScore(current.temp) +
        rainScore(rainExpected);

    return score.clamp(0, 100);
  }

  // ===============================
  // 🌱 PLANT-AWARE RISK SCORE (FIXED)
  // ===============================
  int calculatePlantAwareRiskScore(
    WeatherData current,
    List<ForecastData> forecast,
    PlantType plant,
  ) {
    final profile = PlantRiskService.getProfile(plant);

    final bool rainExpected = forecast.any(
      (f) => f.description.toLowerCase().contains("rain"),
    );

    final double weightedScore =
        (humidityScore(current.humidity.toInt()) *
            profile.humiditySensitivity) +
        (temperatureScore(current.temp) *
            profile.temperatureSensitivity) +
        (rainScore(rainExpected) *
            profile.rainSensitivity);

    return weightedScore.round().clamp(0, 100);
  }

  // ===============================
  // 🚦 SCORE → LEVEL
  // ===============================
  String riskLevel(int score) {
    if (score >= 70) return "High";
    if (score >= 40) return "Medium";
    return "Low";
  }

  // ===============================
  // 🌱 PLANT-AWARE MAIN RISK ALERT
  // ===============================
  List<RiskAlert> analyzePlantAwareRisk(
    WeatherData current,
    List<ForecastData> forecast,
    PlantType plant,
  ) {
    final List<RiskAlert> alerts = [];

    final int score =
        calculatePlantAwareRiskScore(current, forecast, plant);
    final String level = riskLevel(score);

    alerts.add(
      RiskAlert(
        title:
            "$level ${plant.name.toUpperCase()} Disease Risk ($score/100)",
        message:
            "Risk is calculated based on weather conditions and crop sensitivity.",
        severity: level,
      ),
    );

    return alerts;
  }

  // ===============================
  // 🧠 WHY THIS RISK? (PLANT-AWARE)
  // ===============================
  RiskExplanation buildExplanation(
    WeatherData current,
    List<ForecastData> forecast,
    PlantType plant,
  ) {
    final List<String> factors = [];

    factors.add("Selected crop: ${plant.name.toUpperCase()}");

    if (current.humidity >= 70) {
      factors.add(
        "High humidity (${current.humidity.toInt()}%) significantly affects this crop.",
      );
    }

    final bool rainExpected = forecast.any(
      (f) => f.description.toLowerCase().contains("rain"),
    );

    if (rainExpected) {
      factors.add(
        "Rain increases disease spread risk for this plant.",
      );
    }

    if (current.temp >= 18 && current.temp <= 28) {
      factors.add(
        "Temperature (${current.temp.toStringAsFixed(1)}°C) is suitable for fungal growth.",
      );
    }

    return RiskExplanation(
      summary:
          "Risk is calculated based on weather conditions and the selected crop's sensitivity.",
      factors: factors,
    );
  }
}
