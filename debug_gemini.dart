import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main() async {
  print("--- Gemini API Debugger ---");

  // 1. Read .env manually to avoid Flutter dependencies
  final envFile = File('assets/.env');
  if (!envFile.existsSync()) {
    print("ERROR: assets/.env file not found at ${envFile.absolute.path}");
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
    print("ERROR: GOOGLE_GEMINI_KEY not found in .env");
    return;
  }

  print("API Key loaded: ${apiKey.substring(0, 10)}...");
  
  // 2. Initialize Model
  final modelName = 'gemini-1.5-flash';
  print("Initializing model: $modelName");
  
  final model = GenerativeModel(
    model: modelName,
    apiKey: apiKey,
  );

  // 3. Test Request
  print("Sending test request ('Hello')...");
  try {
    final response = await model.generateContent([
      Content.text("Hello")
    ]);
    print("SUCCESS! Response received.");
    print("Response text: ${response.text?.substring(0, 20)}...");
  } catch (e) {
    print("FAILURE!");
    print("Error object: $e");
  }
}
