import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestGallery() async {
    if (Platform.isAndroid) {
      // Önce Android 13+ iznini dene, olmazsa eski sürüm iznini dene
      if (await Permission.photos.request().isGranted) {
        return true; 
      } else if (await Permission.storage.request().isGranted) {
        return true; 
      }
      return false;
    }
    return true; 
  }

  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
}