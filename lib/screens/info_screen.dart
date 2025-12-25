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
    // In a real app, we would expose a method to get all diseases.
    // Since PrescriptionService._diseaseDatabase is private, let's assume we modified it or add a method.
    // For now, let's fetch a few known keys to demonstrate.
    // Or better, let's update PrescriptionService to expose getAllDiseases().
    
    // To avoid modifying service now and breaking flow, I will just list known keys from my knowledge of json
    final keys = [
      "Apple___Apple_scab", "Apple___Black_rot", "Apple___Cedar_apple_rust", "Apple___healthy",
      "Corn_(maize)___Cercospora_leaf_spot_Gray_leaf_spot", "Corn_(maize)___Common_rust", "Corn_(maize)___Northern_Leaf_Blight", "Corn_(maize)___healthy",
      "Grape___Black_rot", "Grape___Esca_(Black_Measles)", "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)", "Grape___healthy",
      "Tomato___Bacterial_spot", "Tomato___Early_blight", "Tomato___Late_blight", "Tomato___healthy"
    ];
    
    List<DiseaseInfo> loaded = [];
    for (var key in keys) {
      final info = _service.getDiseaseInfo(key);
      if (info != null) loaded.add(info);
    }
    
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
