import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print("--- Gemini API Internal Debugger (Raw HTTP) ---");

  // 1. Read .env manually
  final envFile = File('assets/.env');
  if (!envFile.existsSync()) {
    print("ERROR: assets/.env file not found");
    return;
  }
  
  final lines = await envFile.readAsLines();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GOOGLE_GEMINI_KEY=')) {
      apiKey = line.split('=')[1].trim();
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print("ERROR: Key not found in .env");
    return;
  }

  print("API Key loaded: ${apiKey.substring(0, 10)}...");

  // 2. Construct URL
  final model = 'gemini-1.5-flash';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

  print("Target URL: https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=HIDDEN");

  // 3. Send Request
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{
          "parts": [{"text": "Hello from manual debug check"}]
        }]
      }),
    );

    print("\n--- RESPONSE ---");
    print("Status Code: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      print("\nSUCCESS: API is working!");
    } else {
      print("\nFAILURE: Check the error message above.");
    }

  } catch (e) {
    print("EXCEPTION: $e");
  }
}
