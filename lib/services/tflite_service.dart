import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  /// 📦 Model ve label dosyalarını yükler
  Future<void> loadModel() async {
    debugPrint("🟡 MODEL LOAD BAŞLADI");

    final options = InterpreterOptions()..threads = 4;

    // 🔑 DOĞRU: assets/ YAZMIYORUZ
    _interpreter = await Interpreter.fromAsset(
      'assets/model/plant_disease_model.tflite',
      options: options,
    );

    // Label dosyası normal asset gibi okunur
    final labelData =
        await rootBundle.loadString('assets/model/labels.txt');

    _labels = labelData
        .split('\n')
        .map((e) => e.trim().split(' ').last)
        .where((e) => e.isNotEmpty)
        .toList();

    debugPrint("🟢 MODEL YÜKLENDİ | Label sayısı: ${_labels.length}");
  }

  /// 🧠 Görselden hastalık tahmini yapar
  String predict(Uint8List imageBytes) {
    if (_interpreter == null || _labels.isEmpty) {
      throw Exception("Model veya etiketler yüklenmedi!");
    }

    // 1️⃣ Görüntüyü decode et
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception("Görüntü çözümlenemedi");
    }

    // 2️⃣ Resize (MobileNetV2 → 224x224)
    final resized = img.copyResize(image, width: 224, height: 224);

    // 3️⃣ Normalize et
    final input = Float32List(1 * 224 * 224 * 3);
    int index = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    // 4️⃣ Modeli çalıştır
    final output =
        List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(
      input.reshape([1, 224, 224, 3]),
      output,
    );

    // 5️⃣ En yüksek skoru bul
    final scores = output[0] as List<double>;
    int maxIndex = 0;
    double maxScore = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    return _labels[maxIndex];
  }
}
