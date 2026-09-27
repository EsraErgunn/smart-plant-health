import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_app_clean/models/disease_model.dart';
import 'package:my_flutter_app_clean/services/tflite_service.dart';

void main() {
  group('TFLiteService.parseLabels', () {
    test('keeps labels that contain spaces intact', () {
      const data = '0 Apple___Apple_scab\n'
          '4 Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot\r\n'
          '\n';
      expect(TFLiteService.parseLabels(data), [
        'Apple___Apple_scab',
        'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
      ]);
    });
  });

  group('TFLiteService.toProbabilities', () {
    test('leaves probabilities unchanged', () {
      expect(TFLiteService.toProbabilities([0.1, 0.7, 0.2]), [0.1, 0.7, 0.2]);
    });

    test('applies softmax to logits', () {
      final probs = TFLiteService.toProbabilities([2.0, 1.0, -1.0]);
      expect(probs.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
      expect(probs[0], greaterThan(probs[1]));
      expect(probs[1], greaterThan(probs[2]));
    });
  });

  test('every model label has an entry in disease_data.json', () {
    final labels = TFLiteService.parseLabels(
        File('assets/model/labels.txt').readAsStringSync());
    final data = json.decode(
            File('assets/data/disease_data.json').readAsStringSync())
        as Map<String, dynamic>;

    expect(labels, isNotEmpty);
    for (final label in labels) {
      expect(data.containsKey(label), isTrue, reason: 'missing: $label');
      final info = DiseaseInfo.fromJson(label, data[label]);
      expect(info.name, isNot('Unknown Disease'), reason: label);
    }
  });
}
