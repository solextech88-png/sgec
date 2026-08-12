class University {
  final String id;
  final String name;
  final String? city;
  final String? type;
  final String countryName;
  final String region;
  final String? logoUrl;

  University({
    required this.id,
    required this.name,
    this.city,
    this.type,
    required this.countryName,
    required this.region,
    this.logoUrl,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    final country = json['country'] as Map<String, dynamic>?;
    return University(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      type: json['type'],
      countryName: country?['name'] ?? '',
      region: country?['region'] ?? '',
      logoUrl: json['logoUrl'],
    );
  }
}
