import '../models/plant_type.dart';
import '../models/plant_risk_profile.dart';

class PlantRiskService {
  static const Map<PlantType, PlantRiskProfile> profiles = {
    PlantType.corn: PlantRiskProfile(
      humiditySensitivity: 1.2,
      temperatureSensitivity: 1.1,
      rainSensitivity: 1.0,
    ),
    PlantType.tomato: PlantRiskProfile(
      humiditySensitivity: 1.4,
      temperatureSensitivity: 1.3,
      rainSensitivity: 1.3,
    ),
    PlantType.apple: PlantRiskProfile(
      humiditySensitivity: 1.3,
      temperatureSensitivity: 1.2,
      rainSensitivity: 1.2,
    ),
    PlantType.grape: PlantRiskProfile(
      humiditySensitivity: 1.5,
      temperatureSensitivity: 1.3,
      rainSensitivity: 1.4,
    ),
  };

  static PlantRiskProfile getProfile(PlantType plant) {
    return profiles[plant]!;
  }
}
