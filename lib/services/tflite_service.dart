import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Tahmin sonucu: etiket ve 0-1 arası güven skoru.
class Prediction {
  final String label;
  final double confidence;

  const Prediction(this.label, this.confidence);
}

class TFLiteService {
  /// Bu değerin altındaki tahminler "tanınmadı" kabul edilir.
  static const double confidenceThreshold = 0.5;

  Interpreter? _interpreter;
  List<String> _labels = [];

  /// 📦 Model ve label dosyalarını yükler
  Future<void> loadModel() async {
    debugPrint("🟡 MODEL LOAD BAŞLADI");

    final options = InterpreterOptions()..threads = 4;

    _interpreter = await Interpreter.fromAsset(
      'assets/model/plant_disease_model.tflite',
      options: options,
    );

    // Label dosyası normal asset gibi okunur
    final labelData =
        await rootBundle.loadString('assets/model/labels.txt');

    _labels = parseLabels(labelData);

    debugPrint("🟢 MODEL YÜKLENDİ | Label sayısı: ${_labels.length}");
  }

  /// `labels.txt` satırlarını ("0 Apple___Apple_scab") etiket listesine çevirir.
  /// Etiketin kendisi boşluk içerebildiği için yalnızca ilk boşluktan bölünür.
  static List<String> parseLabels(String data) {
    return data
        .split('\n')
        .map((e) {
          final line = e.trim();
          final firstSpace = line.indexOf(' ');
          return firstSpace != -1 ? line.substring(firstSpace + 1).trim() : line;
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Model çıktısı zaten olasılık değilse (logit) softmax uygular.
  static List<double> toProbabilities(List<double> scores) {
    final sum = scores.fold<double>(0, (a, b) => a + b);
    final isProbability =
        scores.every((s) => s >= 0 && s <= 1) && (sum - 1).abs() < 0.01;
    if (isProbability) return scores;

    final maxScore = scores.reduce(math.max);
    final exps = scores.map((s) => math.exp(s - maxScore)).toList();
    final expSum = exps.fold<double>(0, (a, b) => a + b);
    return exps.map((e) => e / expSum).toList();
  }

  /// 🧠 Görselden hastalık tahmini yapar
  Prediction predict(Uint8List imageBytes) {
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
    final scores = toProbabilities(List<double>.from(output[0] as List));
    int maxIndex = 0;
    double maxScore = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    return Prediction(_labels[maxIndex], maxScore);
  }
}
