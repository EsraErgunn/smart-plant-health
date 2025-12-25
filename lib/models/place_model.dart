class Place {
  final String id;
  final String name;
  final String type; // 'expert' or 'store'
  final double lat;
  final double lng;
  final String address;
  final String phone;

  Place({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.address,
    required this.phone,
  });
}
