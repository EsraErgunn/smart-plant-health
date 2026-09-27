import 'package:flutter/material.dart';
import '../models/disease_model.dart';
import '../services/prescription_service.dart';
import '../services/gemini_service.dart';
import 'map_screen.dart';

class PrescriptionScreen extends StatefulWidget {
  final String diseaseKey;

  const PrescriptionScreen({required this.diseaseKey, super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final GeminiService _geminiService = GeminiService();
  DiseaseInfo? _diseaseInfo;
  bool _isLoading = true;

  // Chatbot state
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isChatLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _prescriptionService.loadDiseaseData();
    setState(() {
      _diseaseInfo = _prescriptionService.getDiseaseInfo(widget.diseaseKey);
      _isLoading = false;
    });
    // Initialize Gemini silently
    _geminiService.initialize();
  }

  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text.trim();
    setState(() {
      _chatHistory.add({"role": "user", "message": userMessage});
      _isChatLoading = true;
      _chatController.clear();
    });

    final context = _diseaseInfo?.name ?? widget.diseaseKey;
    final response = await _geminiService.askQuestion(userMessage, context);

    setState(() {
      _chatHistory.add({"role": "bot", "message": response});
      _isChatLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_diseaseInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Not Found")),
        body: Center(child: Text("No data for ${widget.diseaseKey}")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_diseaseInfo!.name),
        backgroundColor: _getRiskColor(_diseaseInfo!.risk),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRiskColor(_diseaseInfo!.risk).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getRiskColor(_diseaseInfo!.risk)),
              ),
              child: Text(
                "Risk Level: ${_diseaseInfo!.risk}",
                style: TextStyle(
                  color: _getRiskColor(_diseaseInfo!.risk),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildSection("Symptoms", _diseaseInfo!.symptoms),
            _buildSection("Causes", _diseaseInfo!.causes),
            _buildSection("Treatment", _diseaseInfo!.treatment),
            _buildSection("Prevention", _diseaseInfo!.prevention),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text("Find Nearby Dealers", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(diseaseName: widget.diseaseKey),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            const Divider(height: 40),
            
            // Chatbot Section
            const Text("🌱 Plant Doctor AI",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final msg = _chatHistory[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.green.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(msg['message']!),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isChatLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: "Ask about this disease...",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.green),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(e)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
