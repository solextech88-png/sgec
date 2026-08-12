class StudentDocument {
  final String id;
  final String type;
  final String fileUrl;
  final String fileName;
  final bool verifiedByConsultant;

  StudentDocument({
    required this.id,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.verifiedByConsultant,
  });

  factory StudentDocument.fromJson(Map<String, dynamic> json) {
    return StudentDocument(
      id: json['id'],
      type: json['type'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      verifiedByConsultant: json['verifiedByConsultant'] ?? false,
    );
  }
}

/// Mirrors backend DocumentType enum — keep in sync with prisma/schema.prisma.
const List<String> kDocumentTypes = [
  'PASSPORT',
  'PHOTOGRAPH',
  'TRANSCRIPT',
  'CERTIFICATE',
  'ENGLISH_TEST',
  'CV',
  'PERSONAL_STATEMENT',
  'RESEARCH_PROPOSAL',
  'RECOMMENDATION_LETTER',
  'OTHER',
];
