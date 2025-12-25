class City {
  final String name;
  final double lat;
  final double lon;
  final String country;

  City({
    required this.name,
    required this.lat,
    required this.lon,
    required this.country,
  });

    factory City.fromJson(Map<String, dynamic> json) {
      return City(
        name: json['name'],
        country: json['country'],
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );
  }
}
