import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class DiagnosisDatabaseService {
  static const String _boxName = 'diagnoses';

  // Initialize Hive Box
  Future<void> init() async {
    try {
      await Hive.openBox<String>(_boxName);
    } catch (e) {
      debugPrint("Hive init error: $e");
      // Fallback or retry logic could go here
    }
  }

  // Get all saved image paths
  List<String> getAllImages() {
    try {
      final box = Hive.box<String>(_boxName);
      return box.values.toList();
    } catch (e) {
      debugPrint("Fetch images error: $e");
      return [];
    }
  }

  // Add a new image path
  Future<void> addImage(String path) async {
    try {
      final box = Hive.box<String>(_boxName);
      await box.add(path);
    } catch (e) {
      debugPrint("Add image error: $e");
      throw Exception("Failed to save image");
    }
  }

  // Delete an image by its path (value)
  // Note: Hive lists are index-based usually, but we can find key by value if needed.
  // Or simplifying to delete by index if the UI matches the list order.
  // For safety in this grid, we'll try to delete by key finding the value.
  Future<void> deleteImage(String path) async {
    try {
      final box = Hive.box<String>(_boxName);
      
      // Find key for valid deletion
      final Map<dynamic, String> map = box.toMap().cast<dynamic, String>();
      dynamic keyToDelete;
      map.forEach((key, val) {
        if (val == path) {
          keyToDelete = key;
        }
      });

      if (keyToDelete != null) {
        await box.delete(keyToDelete);
      }
    } catch (e) {
      debugPrint("Delete image error: $e");
      throw Exception("Failed to delete image");
    }
  }
}
