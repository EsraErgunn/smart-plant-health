import '../models/place_model.dart';

class DiseaseFilter {
  
  static String getRequiredMedicineType(String diseaseType) {
    switch (diseaseType.toLowerCase()) {
      case 'fungal':
      case 'fungus':
      case 'blight':
      case 'rust':
      case 'mildew':
        return 'fungicide';
      case 'insect':
      case 'pest':
      case 'worm':
      case 'beetle':
        return 'insecticide';
      case 'bacterial':
      case 'bacteriosis':
        return 'bactericide';
      case 'viral':
      case 'mosaic':
        return 'antiviral/support'; // No direct cure usually
      default:
        return 'general agricultural supplies';
    }
  }

  static List<PlaceModel> filterPlaces(
    List<PlaceModel> places,
  ) {
    // Filter by rating (e.g., >= 3.5) and take top 5
    return places
        .where((p) => p.rating >= 3.5)
        .take(5)
        .toList();
  }
}
