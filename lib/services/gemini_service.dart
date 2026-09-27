import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/env.dart';

class GeminiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  Future<void> initialize() async {
    const apiKey = Env.geminiKey;
    if (apiKey.isEmpty) {
      debugPrint("Gemini API Key missing.");
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
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
    } catch (e, stackTrace) {
      debugPrint("Gemini API Error: $e");
      debugPrint("Stack Trace: $stackTrace");
      return "Error communicating with AI. Please try again.";
    }
  }
}
