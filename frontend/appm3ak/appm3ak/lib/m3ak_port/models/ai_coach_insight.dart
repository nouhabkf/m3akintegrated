class AiCoachInsight {
  final String headline;
  final String focusArea;
  final String priority;
  final List<String> recommendations;
  final int confidenceScore;
  final String nextMilestone;

  const AiCoachInsight({
    required this.headline,
    required this.focusArea,
    required this.priority,
    required this.recommendations,
    required this.confidenceScore,
    required this.nextMilestone,
  });
}

