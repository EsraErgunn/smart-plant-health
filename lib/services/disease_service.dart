import 'dart:convert';
import 'package:flutter/services.dart';

class DiseaseService {
  static Future<Map<String, dynamic>?> getDisease(String label) async {
    final jsonString =
        await rootBundle.loadString('assets/data/disease_data.json');
    final data = json.decode(jsonString);

    if (data.containsKey(label)) {
      return Map<String, dynamic>.from(data[label]);
    }
    return null;
  }
}
