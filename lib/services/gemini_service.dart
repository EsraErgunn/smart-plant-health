import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  Future<void> initialize() async {
    final apiKey = dotenv.env['GOOGLE_GEMINI_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('AIzaSyCM_7Yy4UJCX1LMaWgYy0mX-gXfPTT1cVE')) {
      print("Gemini API Key missing or invalid.");
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String> askQuestion(String question, String diseaseContext) async {
    if (_model == null) await initialize();
    if (_model == null) return "AI Service not available. Please check API Key.";

    try {
      // Start chat if not exists
      _chatSession ??= _model!.startChat(history: [
        Content.text(
            "You are an expert plant pathologist and agricultural consultant. "
            "The user is asking about a plant disease. "
            "Context: $diseaseContext. "
            "Provide helpful, concise, and practical advice.")
      ]);

      final response = await _chatSession!.sendMessage(Content.text(question));
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      return "Error communicating with AI: $e";
    }
  }
}
