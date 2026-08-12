class University {
  final String id;
  final String name;
  final String? city;
  final String? type;
  final String countryName;
  final String region;

  University({
    required this.id,
    required this.name,
    this.city,
    this.type,
    required this.countryName,
    required this.region,
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
    );
  }
}

class Programme {
  final String id;
  final String name;
  final String level;
  final String? fieldOfStudy;
  final int? durationMonths;
  final num? tuitionFeeAmount;
  final String? tuitionFeeCurrency;
  final String? entryRequirements;
  final String? englishRequirement;
  final DateTime? applicationDeadline;
  final String? scholarshipsAvailable;
  final List<String> startDates;
  final bool? casAvailable;
  final String? visaInfo;
  final String? postGradWorkRights;
  final University? university;

  Programme({
    required this.id,
    required this.name,
    required this.level,
    this.fieldOfStudy,
    this.durationMonths,
    this.tuitionFeeAmount,
    this.tuitionFeeCurrency,
    this.entryRequirements,
    this.englishRequirement,
    this.applicationDeadline,
    this.scholarshipsAvailable,
    this.startDates = const [],
    this.casAvailable,
    this.visaInfo,
    this.postGradWorkRights,
    this.university,
  });

  factory Programme.fromJson(Map<String, dynamic> json) {
    return Programme(
      id: json['id'],
      name: json['name'],
      level: json['level'],
      fieldOfStudy: json['fieldOfStudy'],
      durationMonths: json['durationMonths'],
      tuitionFeeAmount: json['tuitionFeeAmount'] != null
          ? num.tryParse(json['tuitionFeeAmount'].toString())
          : null,
      tuitionFeeCurrency: json['tuitionFeeCurrency'],
      entryRequirements: json['entryRequirements'],
      englishRequirement: json['englishRequirement'],
      applicationDeadline: json['applicationDeadline'] != null
          ? DateTime.tryParse(json['applicationDeadline'])
          : null,
      scholarshipsAvailable: json['scholarshipsAvailable'],
      startDates: (json['startDates'] as List?)?.map((e) => e.toString()).toList() ?? [],
      casAvailable: json['casAvailable'],
      visaInfo: json['visaInfo'],
      postGradWorkRights: json['postGradWorkRights'],
      university: json['university'] != null ? University.fromJson(json['university']) : null,
    );
  }
}
