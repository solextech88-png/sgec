import 'programme.dart';

class StudentApplication {
  final String id;
  final String status;
  final double? aiMatchScore;
  final Programme programme;
  final DateTime createdAt;

  StudentApplication({
    required this.id,
    required this.status,
    this.aiMatchScore,
    required this.programme,
    required this.createdAt,
  });

  factory StudentApplication.fromJson(Map<String, dynamic> json) {
    return StudentApplication(
      id: json['id'],
      status: json['status'],
      aiMatchScore: (json['aiMatchScore'] as num?)?.toDouble(),
      programme: Programme.fromJson(json['programme']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
