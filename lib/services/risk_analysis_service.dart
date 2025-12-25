import '../models/weather_model.dart';
import '../models/plant_type.dart';

class RiskAlert {
  final String title;
  final String message;
  final String severity; // Low, Medium, High

  RiskAlert({required this.title, required this.message, required this.severity});
}

class RiskExplanation {
  final String summary;
  final List<String> factors;
  
  RiskExplanation({required this.summary, required this.factors});
}

class RiskAnalysisService {
  
  /// General Risk Analysis
  List<RiskAlert> analyzeRisk(WeatherData current, List<ForecastData> forecast) {
    List<RiskAlert> alerts = [];

    // Fungal Risk
    if (current.humidity > 70 && current.temp > 20 && current.temp < 30) {
      alerts.add(RiskAlert(
        title: "High Fungal Disease Risk",
        message: "High humidity and moderate temps favor fungal growth.",
        severity: "High",
      ));
    }

    // Pest Risk
    if (current.temp > 30) {
      alerts.add(RiskAlert(
        title: "Pest Activity Warning",
        message: "High temperatures may increase pest reproduction.",
        severity: "Medium",
      ));
    }
    
    // Rain
    bool rainExpected = forecast.any((f) => f.description.toLowerCase().contains("rain"));
    if (rainExpected) {
      alerts.add(RiskAlert(
        title: "Rain Forecast",
        message: "Avoid spraying chemicals. Rain expected within 5 days.",
        severity: "Medium",
      ));
    }

    return alerts;
  }

  /// Plant-Specific Risk Analysis
  List<RiskAlert> analyzePlantAwareRisk(WeatherData current, List<ForecastData> forecast, PlantType plant) {
    List<RiskAlert> alerts = [];

    // 1. Temperature Check
    if (current.temp < plant.minTemp) {
      alerts.add(RiskAlert(
        title: "Cold Stress (${plant.name})",
        message: "Temperature is below ideal range for ${plant.name}.",
        severity: "High",
      ));
    } else if (current.temp > plant.maxTemp) {
      alerts.add(RiskAlert(
        title: "Heat Stress (${plant.name})",
        message: "Temperature exceeds ideal range for ${plant.name}.",
        severity: "Medium",
      ));
    }

    // 2. Humidity Check (Simplified: most crops dislike very high humidity due to fungus)
    if (current.humidity > 80) {
       alerts.add(RiskAlert(
        title: "Fungal Risk (${plant.name})",
        message: "Excessive humidity poses a threat to ${plant.name}.",
        severity: "High",
      ));
    }

    return alerts;
  }

  /// Build 'Why this risk?' explanation
  RiskExplanation buildExplanation(WeatherData current, List<ForecastData> forecast, PlantType plant) {
    List<String> factors = [];
    
    factors.add("Current Temperature: ${current.temp}°C (Ideal: ${plant.minTemp}-${plant.maxTemp}°C)");
    factors.add("Humidity: ${current.humidity}%");
    
    // Check constraints
    if (current.temp < plant.minTemp || current.temp > plant.maxTemp) {
      factors.add("❌ Temperature is out of optimal range.");
    } else {
      factors.add("✅ Temperature is optimal.");
    }
    
    if (current.humidity > 70) {
       factors.add("⚠️ High humidity increases disease probability.");
    }

    return RiskExplanation(
      summary: "Risk based on ${plant.name} requirements.",
      factors: factors
    );
  }

  /// Calculates a simple 0-100 risk score for each day in the forecast
  /// This is used for the Visualization Chart
  List<double> calculateDailyRisks(List<ForecastData> forecasts) {
    return forecasts.map((day) {
      double score = 0.0;
      
      // 1. Humidity Contribution (0-50 points)
      // High humidity is generally risky for diseases
      if (day.humidity > 80) score += 50;
      else if (day.humidity > 60) score += 30;
      else if (day.humidity > 40) score += 10;
      
      // 2. Temperature Contribution (0-50 points)
      // Identify "Training Zone" for pathogens (often 20-30C)
      if (day.temp >= 20 && day.temp <= 30) score += 50;
      else if (day.temp > 30) score += 30; // Heat stress
      else if (day.temp < 15) score += 20; // Cold stress
      
      return score;
    }).toList();
  }
}
