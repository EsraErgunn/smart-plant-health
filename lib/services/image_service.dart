import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromCamera() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.camera);
    return file != null ? File(file.path) : null;
  }

  Future<File?> pickFromGallery() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery);
    return file != null ? File(file.path) : null;
  }
}
