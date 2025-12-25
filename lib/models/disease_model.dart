class DiseaseInfo {
  final String key;
  final String name;
  final String risk;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatment;
  final List<String> prevention;

  DiseaseInfo({
    required this.key,
    required this.name,
    required this.risk,
    required this.symptoms,
    required this.causes,
    required this.treatment,
    required this.prevention,
  });

  factory DiseaseInfo.fromJson(String key, Map<String, dynamic> json) {
    return DiseaseInfo(
      key: key,
      name: json['name'] ?? 'Unknown Disease',
      risk: json['risk'] ?? 'Unknown',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      causes: List<String>.from(json['causes'] ?? []),
      treatment: List<String>.from(json['treatment'] ?? []),
      prevention: List<String>.from(json['prevention'] ?? []),
    );
  }
}
