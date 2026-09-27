import 'package:flutter/material.dart';
import '../services/prescription_service.dart';
import '../models/disease_model.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final PrescriptionService _service = PrescriptionService();
  final List<DiseaseInfo> _diseases = [];

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    await _service.loadDiseaseData();
    final loaded = _service.getAllDiseases();

    if (mounted) {
      setState(() {
        _diseases.addAll(loaded);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Disease Library")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _diseases.length,
        itemBuilder: (context, index) {
          final disease = _diseases[index];
          if (disease.name.contains("Sağlıklı") || disease.name.contains("healthy")) return const SizedBox.shrink(); // Skip healthy
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(disease.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Risk: ${disease.risk}", 
                style: TextStyle(color: disease.risk == 'High' ? Colors.red : Colors.orange)),
              leading: const Icon(Icons.library_books, color: Colors.green),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Symptoms:", style: TextStyle(fontWeight: FontWeight.bold)),
                      ...disease.symptoms.map((e) => Text("• $e")),
                      const SizedBox(height: 8),
                      const Text("Prevention:", style: TextStyle(fontWeight: FontWeight.bold)),
                      ...disease.prevention.map((e) => Text("• $e")),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
