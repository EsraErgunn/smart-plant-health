class WeatherData {
  final double temp;
  final double humidity;
  final String description;
  final String icon;
  final String city;

  WeatherData({
    required this.temp,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.city,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temp: (json['main']['temp'] ?? 0.0).toDouble(),
      humidity: (json['main']['humidity'] ?? 0).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
      city: json['name'] ?? '',
    );
  }
}

class ForecastData {
  final DateTime date;
  final double temp;
  final double humidity;
  final String description;
  final String icon;

  ForecastData({
    required this.date,
    required this.temp,
    required this.humidity,
    required this.description,
    required this.icon,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      date: DateTime.fromMillisecondsSinceEpoch((json['dt'] * 1000).toInt()),
      temp: (json['main']['temp'] ?? 0.0).toDouble(),
      humidity: (json['main']['humidity'] ?? 0).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
    );
  }
}
