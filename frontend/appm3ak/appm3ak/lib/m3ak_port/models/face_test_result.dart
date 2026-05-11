class FaceTestResult {
  final bool recognized;
  final String? personName;
  final String? relation;
  final double confidence;
  final double distance;
  final double threshold;
  final bool faceDetected;
  final bool embeddingGenerated;
  final int totalPersons;
  final int totalEmbeddings;
  final List<PersonMatch> allMatches;

  FaceTestResult({
    required this.recognized,
    this.personName,
    this.relation,
    required this.confidence,
    required this.distance,
    required this.threshold,
    required this.faceDetected,
    required this.embeddingGenerated,
    required this.totalPersons,
    required this.totalEmbeddings,
    required this.allMatches,
  });
}

class PersonMatch {
  final String personName;
  final String relation;
  final double distance;
  final double confidence;

  PersonMatch({
    required this.personName,
    required this.relation,
    required this.distance,
    required this.confidence,
  });
}

