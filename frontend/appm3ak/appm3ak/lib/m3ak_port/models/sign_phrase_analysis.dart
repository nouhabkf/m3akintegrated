class SignPhraseAnalysis {
  final String normalizedText;
  final String translatedText;
  final String detectedContext;
  final int confidence;
  final List<String> gestures;
  final List<String> tips;

  const SignPhraseAnalysis({
    required this.normalizedText,
    required this.translatedText,
    required this.detectedContext,
    required this.confidence,
    required this.gestures,
    required this.tips,
  });
}

