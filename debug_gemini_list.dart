import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print("--- Gemini API List Models Debugger ---");
  final envFile = File('assets/.env');
  final lines = await envFile.readAsLines();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GOOGLE_GEMINI_KEY=')) {
      apiKey = line.split('=')[1].trim();
    }
  }

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  try {
    final response = await http.get(url);
    print("Status: ${response.statusCode}");
    if (response.statusCode == 200) {
       final json = jsonDecode(response.body);
       final models = json['models'] as List;
       final file = File('all_models.txt');
       final sink = file.openWrite();
       for (var m in models) {
         sink.writeln(m['name']);
       }
       await sink.close();
       print("Written to all_models.txt");
    } else {
      print("Error: ${response.body}");
    }
  } catch (e) {
    print(e);
  }
}
