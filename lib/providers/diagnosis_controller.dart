import 'package:flutter/material.dart';
import '../services/diagnosis_database_service.dart';
import '../services/image_picker_service.dart';

class DiagnosisController extends ChangeNotifier {
  final DiagnosisDatabaseService _dbService;
  final ImagePickerService _pickerService;

  List<String> _images = [];
  bool _isLoading = false;
  String? _error;

  List<String> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DiagnosisController({
    required DiagnosisDatabaseService dbService,
    required ImagePickerService pickerService,
  })  : _dbService = dbService,
        _pickerService = pickerService;

  // Load initial data
  Future<void> loadImages() async {
    _setLoading(true);
    try {
      // Ensure DB is ready just in case, though main should handle it.
      // Ideally main calls init(), but verifying here doesn't hurt if cheap.
      _images = _dbService.getAllImages();
      // Reverse to show newest first
      _images = _images.reversed.toList();
    } catch (e) {
      _error = "Failed to load gallery";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndSaveImage({bool fromCamera = false}) async {
    _error = null;
    notifyListeners();

    try {
      final String? path = fromCamera 
          ? await _pickerService.pickImageFromCamera()
          : await _pickerService.pickImageFromGallery();

      if (path != null) {
        await saveImage(path);
      }
    } catch (e) {
      _error = "Failed to add image";
      notifyListeners();
    }
  }

  Future<void> saveImage(String path) async {
    try {
      await _dbService.addImage(path);
      await loadImages();
    } catch (e) {
      debugPrint("Auto-save error: $e");
      // Don't necessarily block UI for background save error, but could set error state
    }
  }

  Future<void> deleteImage(String path) async {
    try {
      await _dbService.deleteImage(path);
      await loadImages(); 
    } catch (e) {
      _error = "Failed to delete image";
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
