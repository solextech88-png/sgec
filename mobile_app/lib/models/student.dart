class StudentProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? nationality;
  final String? countryOfResidence;
  final String? highestQualification;

  StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.nationality,
    this.countryOfResidence,
    this.highestQualification,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      nationality: json['nationality'],
      countryOfResidence: json['countryOfResidence'],
      highestQualification: json['highestQualification'],
    );
  }
}
