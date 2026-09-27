import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/disease_model.dart';

class PrescriptionService {
  Map<String, DiseaseInfo> _diseaseDatabase = {};

  /// Load disease data from JSON asset
  Future<void> loadDiseaseData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/disease_data.json');
      final Map<String, dynamic> data = json.decode(response);

      _diseaseDatabase = data.map((key, value) {
        return MapEntry(key, DiseaseInfo.fromJson(key, value));
      });
    } catch (e) {
      debugPrint("Error loading disease data: $e");
    }
  }

  /// Get disease info by key (e.g., "Apple___Black_rot")
  DiseaseInfo? getDiseaseInfo(String key) {
    return _diseaseDatabase[key];
  }

  /// All diseases in the order they appear in the JSON file
  List<DiseaseInfo> getAllDiseases() {
    return _diseaseDatabase.values.toList();
  }
}
