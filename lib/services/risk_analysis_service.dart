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
  final String suggestedAction; 
  
  RiskExplanation({
    required this.summary, 
    required this.factors,
    required this.suggestedAction,
  });
}

// Internal data structure for disease logic
class DiseaseRiskProfile {
  final PlantType plant;
  final String diseaseName; 
  final double minTemp;
  final double maxTemp;
  final double minHumidity;
  final String action; 

  const DiseaseRiskProfile({
    required this.plant,
    required this.diseaseName,
    required this.minTemp,
    required this.maxTemp,
    required this.minHumidity,
    required this.action,
  });
}

class RiskAnalysisService {
  
  // Define the Disease Rules
  static const List<DiseaseRiskProfile> _profiles = [
    DiseaseRiskProfile(
      plant: PlantType.tomato,
      diseaseName: "Domates Mildiyösü (Late Blight)",
      minTemp: 18,
      maxTemp: 29, 
      minHumidity: 80,
      action: "Mildiyö için fungusit uygulaması yapın. Yaprak altlarını kontrol edin.",
    ),
    DiseaseRiskProfile(
      plant: PlantType.tomato,
      diseaseName: "Erken Yanıklık (Early Blight)",
      minTemp: 24,
      maxTemp: 29, 
      minHumidity: 60, 
      action: "Hastalıklı yaprakları temizleyin ve koruyucu ilaçlama yapın.",
    ),
    DiseaseRiskProfile(
      plant: PlantType.corn,
      diseaseName: "Mısır Pası (Common Rust)",
      minTemp: 16,
      maxTemp: 25, 
      minHumidity: 70,
      action: "Pas belirtileri görülürse dayanıklı çeşit ilaçlaması uygulayın.",
    ),
    DiseaseRiskProfile(
      plant: PlantType.corn,
      diseaseName: "Yaprak Yanıklığı (Leaf Blight)",
      minTemp: 18,
      maxTemp: 27, 
      minHumidity: 80,
      action: "Hava sirkülasyonunu artırın ve mantar ilacı uygulayın.",
    ),
    DiseaseRiskProfile(
      plant: PlantType.apple,
      diseaseName: "Kara Leke (Apple Scab)",
      minTemp: 5, 
      maxTemp: 20, 
      minHumidity: 75,
      action: "Özellikle yağmur sonrası koruyucu ilaçlama atın.",
    ),
    DiseaseRiskProfile(
      plant: PlantType.grape,
      diseaseName: "Siyah Çürüklük (Black Rot)",
      minTemp: 20,
      maxTemp: 27, 
      minHumidity: 75,
      action: "Salkımları havalandırın ve sistemik ilaçlama yapın.",
    ),
    DiseaseRiskProfile(
      plant: PlantType.grape,
      diseaseName: "Kurşuni Küf (Botrytis)",
      minTemp: 15,
      maxTemp: 22, 
      minHumidity: 85,
      action: "Salkım etrafındaki yaprakları seyreltin.",
    ),
  ];

  
  DiseaseRiskProfile? _findActiveRisk(PlantType plant, WeatherData current, bool isGreenhouse) {
    try {
      final candidates = _profiles.where((p) => p.plant == plant);
      
      for (final profile in candidates) {
        // If Greenhouse, we assume temp is managed (or warmer), so we iterate leniently on low temp
        // But high temp is still a risk.
        bool tempMatch = false;
        if (isGreenhouse) {
           // In greenhouse, allow temps lower than min to still trigger risk if humidity is super high
           // assuming the greenhouse internal temp is higher than outside.
           // Simplification: Assume internal temp is roughly +5 to +10 C over outside in day if heating/greenhouse effect exists
           // For safety, we just allow the match if outside is at least (minTemp - 10)
           tempMatch = current.temp >= (profile.minTemp - 10) && current.temp <= (profile.maxTemp + 5);
        } else {
           tempMatch = current.temp >= profile.minTemp && current.temp <= profile.maxTemp;
        }

        // Greenhouse humidity is usually higher than outside, so equal match is valid warning
        bool humMatch = current.humidity >= profile.minHumidity;
        
        if (tempMatch && humMatch) {
          return profile; 
        }
      }
    } catch (_) {}
    return null;
  }

  /// Plant-Specific Risk Analysis
  List<RiskAlert> analyzePlantAwareRisk(WeatherData current, List<ForecastData> forecast, PlantType plant, {bool isGreenhouse = false}) {
    List<RiskAlert> alerts = [];

    final activeRisk = _findActiveRisk(plant, current, isGreenhouse);
    
    if (activeRisk != null) {
      alerts.add(RiskAlert(
        title: "Hastalık Riski Uyarısı: ${activeRisk.diseaseName}",
        message: "Tehlike - ${isGreenhouse ? 'Sera ortamında' : 'Mevcut koşullarda'} (Nem %${current.humidity}) ${activeRisk.diseaseName} gelişim riski çok yüksek!",
        severity: "High",
      ));
    } else {
      // Winter / Seasonal Logic
      // If it's very cold and NOT greenhouse, likely no risk for these summer crops
      if (!isGreenhouse && current.temp < 10) {
         alerts.add(RiskAlert(
          title: "Hastalık Riski Düşük",
          message: "Güvenli - Düşük sıcaklık nedeniyle hastalık gelişimi beklenmiyor. (Açık Alan)",
          severity: "Low",
        ));
        
        // Add root rot warning for winter if very wett
        if (current.humidity > 85) {
           alerts.add(RiskAlert(
            title: "Kök Çürüklüğü Riski",
            message: "Dikkat - Kışın aşırı toprak nemi kök hastalıklarına yol açabilir.",
            severity: "Medium",
          ));
        }

      } else if (isGreenhouse && current.humidity > 70) {
         // Greenhouse specific generic warning
         alerts.add(RiskAlert(
          title: "Sera Nem Uyarısı",
          message: "Dikkat - Sera içi nem durgunluğu mantari hastalıkları tetikleyebilir.",
          severity: "Medium",
        ));
      } else {
        bool moderateRisk = current.humidity > 60;
        if (moderateRisk) {
           alerts.add(RiskAlert(
            title: "Hastalık Riski Uyarısı",
            message: "Dikkat - Nem oranı artıyor, hastalık riski oluşabilir.",
            severity: "Medium",
          ));
        } else {
          alerts.add(RiskAlert(
            title: "Hastalık Riski Uyarısı",
            message: "Güvenli - Koşullar hastalık gelişimi için uygun değil.",
            severity: "Low",
          ));
        }
      }
    }

    return alerts;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Build 'Risk Analiz Raporu'
  RiskExplanation buildExplanation(WeatherData current, List<ForecastData> forecast, PlantType plant, {bool isGreenhouse = false}) {
    List<String> factors = [];
    String action = "";
    
    final activeRisk = _findActiveRisk(plant, current, isGreenhouse);

    if (activeRisk != null) {
      factors.add("Seçtiğiniz **${_capitalize(plant.name)}** için modelimizde tanımlı olan **${activeRisk.diseaseName}** riski, yüksek nem (%${current.humidity}) nedeniyle artış göstermektedir.");
      if (isGreenhouse) {
        factors.add("Sera içi sıcaklık ve nem dengesizliği bu riski katlayabilir.");
      } else {
        factors.add("Sıcaklık ve nem değerleri hastalığın yayılması için kritik eşikte.");
      }
      action = activeRisk.action;
    } else {
       // Off Season Logic
       if (!isGreenhouse && current.temp < 12) {
         factors.add("Şu an açık alan üretim sezonu dışındasınız (Düşük Sıcaklık).");
         factors.add("Ancak **SERA** üretimi yapıyorsanız, içerideki nem birikimi risk oluşturabilir.");
         factors.add("Kış aylarında aşırı yağış veya sulama **Kök Çürüklüğü** riskini artırır.");
         
         action = "Üretim yapmıyorsanız işlem gerekmez. Sera üretimi yapıyorsanız 'Sera / Kapalı Alan' modunu açın.";
       } else {
         factors.add("**${_capitalize(plant.name)}** için şu an spesifik bir hastalık riski tespit edilmedi.");
         factors.add("Nem (%${current.humidity}) ve Sıcaklık (${current.temp.toStringAsFixed(1)}°C) normal seviyelerde.");
         action = "Düzenli kontrollere devam edin.";
       }
    }

    return RiskExplanation(
      summary: "Risk Analiz Raporu",
      factors: factors,
      suggestedAction: action,
    );
  }

  List<double> calculateDailyRisks(List<ForecastData> forecasts, {bool isGreenhouse = false}) {
    return forecasts.map((day) {
      double score = 0.0;
      
      // Greenhouse boosts humidity risk score
      double humidityScore = 0;
      if (day.humidity > 80) humidityScore = 50;
      else if (day.humidity > 60) humidityScore = 30;
      else if (day.humidity > 40) humidityScore = 10;
      
      if (isGreenhouse) humidityScore += 10; // Greenhouse penalty
      score += humidityScore;

      // Temp
      if (day.temp >= 20 && day.temp <= 30) score += 50;
      else if (day.temp > 30) score += 30; 
      else if (day.temp < 15) {
        if (isGreenhouse) score += 30; // In greenhouse, assume we heat it up to danger zone
        else score += 0; // Too cold outside for fungus usually
      } 
      
      if (score > 100) score = 100;
      return score;
    }).toList();
  }
}
