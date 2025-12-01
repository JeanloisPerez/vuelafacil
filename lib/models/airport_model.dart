class AirportModel {
  final String name;
  final String city;
  final String country;
  final String code;

  AirportModel({
    required this.name,
    required this.city,
    required this.country,
    required this.code,
  });

  factory AirportModel.fromMap(Map<String, dynamic> map) {
    return AirportModel(
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      code: map['code'] ?? '',
    );
  }
}
