import 'package:equatable/equatable.dart';

/// Modèle correspondant à la réponse backend de:
/// GET /community/posts/:postId/comments/flash-summary
class FlashSummaryModel extends Equatable {
  const FlashSummaryModel({
    required this.summary,
    required this.keyPoints,
    required this.readingTimeSeconds,
    required this.wordReduction,
  });

  factory FlashSummaryModel.fromJson(Map<String, dynamic> json) {
    return FlashSummaryModel(
      summary: json['summary'] as String? ?? '',
      keyPoints: (json['keyPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      readingTimeSeconds:
          (json['readingTimeSeconds'] as num?)?.toInt() ?? 0,
      wordReduction: (json['wordReduction'] as num?)?.toInt() ?? 0,
    );
  }

  final String summary;
  final List<String> keyPoints;
  final int readingTimeSeconds;
  final int wordReduction;

  @override
  List<Object?> get props => [
        summary,
        keyPoints,
        readingTimeSeconds,
        wordReduction,
      ];
}

