import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tflite_service.dart';
import '../services/image_service.dart';
import '../services/permission_service.dart';
import 'prescription_screen.dart';
import '../l10n/gen/app_localizations.dart';
import '../widgets/diagnosis_gallery_modal.dart';
import '../providers/diagnosis_controller.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  final TFLiteService tflite = TFLiteService();
  final ImageService imageService = ImageService();

  File? _image;
  bool _loading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    PermissionService.requestLocation();
  }

  void showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadModel() async {
    try {
      await tflite.loadModel();
      if (!mounted) return;
      setState(() => _modelLoaded = true);
    } catch (e) {
      debugPrint("❌ MODEL LOAD ERROR: $e");
      if (!mounted) return;
      showSnack("Model yüklenemedi");
    }
  }

  Future<void> _processImage(Future<File?> Function() picker) async {
    if (!_modelLoaded) {
      showSnack("Model henüz yüklenmedi");
      return;
    }

    // Request permissions implicitly dealt with by service or check here?
    // The previous code checked permission explicitly. Let's keep it simple for now or check inside buttons.

    setState(() => _loading = true);

    final file = await picker();
    
    if (file == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      final label = tflite.predict(bytes);
      
      if (!mounted) return;

      setState(() {
        _image = file;
        _loading = false;
      });

      // Auto-save to gallery history
      // We use listen: false because we are in a method, not rebuilding UI based on this
      Provider.of<DiagnosisController>(context, listen: false).saveImage(file.path);

      // Navigate to result
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrescriptionScreen(diseaseKey: label),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      showSnack("Hata: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diagnosis),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const DiagnosisGalleryModal(),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_modelLoaded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(l10n.loading, style: const TextStyle(color: Colors.grey)), 
                ),
              
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            l10n.takePhoto, // Using "Take Photo" as prompt or "Bitki Teşhis"? arb says takePhoto
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 30),

              if (_loading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: !_modelLoaded
                        ? null
                        : () async {
                            final granted = await PermissionService.requestCamera();
                            if (granted) {
                              _processImage(imageService.pickFromCamera);
                            } else {
                              showSnack("Camera permission required");
                            }
                          },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.takePhoto),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: !_modelLoaded
                        ? null
                        : () async {
                            final granted = await PermissionService.requestGallery();
                            if (granted) {
                              _processImage(imageService.pickFromGallery);
                            } else {
                              showSnack("Gallery permission required");
                            }
                          },
                    icon: const Icon(Icons.photo_library),
                    label: Text(l10n.gallery),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
