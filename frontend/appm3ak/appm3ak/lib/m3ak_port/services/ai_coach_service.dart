import 'package:appm3ak/m3ak_port/models/ai_coach_insight.dart';

class AiCoachService {
  const AiCoachService();

  AiCoachInsight buildInsight({
    required int currentLevel,
    required int lessonsCompleted,
    required int successStreak,
    required double avgLast5Scores,
    required double errorRate,
    required int avgResponseTimeMs,
  }) {
    final recommendations = <String>[];
    String focusArea = 'Consolidation';
    String priority = 'Moyenne';

    if (avgLast5Scores < 0.55 || errorRate > 0.45) {
      focusArea = 'Fondamentaux Braille';
      priority = 'Elevee';
      recommendations.add('Refaire 5 exercices niveau 1 avant de monter de niveau.');
      recommendations.add('Activer une pause de 30 sec entre 2 questions pour limiter les erreurs.');
    } else if (avgLast5Scores > 0.85 && successStreak >= 5) {
      focusArea = 'Acceleration';
      priority = 'Elevee';
      recommendations.add('Passer au niveau suivant et introduire des mots complets.');
      recommendations.add('Ajouter 1 scenario pratique par jour pour transferer les acquis.');
    } else {
      recommendations.add('Maintenir le rythme actuel avec 10 a 15 minutes quotidiennes.');
    }

    if (avgResponseTimeMs > 7000) {
      recommendations.add('Objectif vitesse: repondre en moins de 7 secondes par exercice.');
    } else {
      recommendations.add('Bonne vitesse: maintenir cette fluidite sur les prochains modules.');
    }

    if (lessonsCompleted < 3) {
      recommendations.add('Completer au moins 3 lecons cette semaine pour stabiliser les bases.');
    } else if (lessonsCompleted >= 10) {
      recommendations.add('Excellente regularite: tenter un challenge quotidien 2 jours de suite.');
    }

    final confidenceScore = _buildConfidenceScore(
      avgLast5Scores: avgLast5Scores,
      errorRate: errorRate,
      successStreak: successStreak,
      avgResponseTimeMs: avgResponseTimeMs,
    );

    final nextMilestone = _nextMilestone(
      currentLevel: currentLevel,
      lessonsCompleted: lessonsCompleted,
      successStreak: successStreak,
    );

    final headline = _headlineFromScore(confidenceScore);

    return AiCoachInsight(
      headline: headline,
      focusArea: focusArea,
      priority: priority,
      recommendations: recommendations.take(3).toList(),
      confidenceScore: confidenceScore,
      nextMilestone: nextMilestone,
    );
  }

  int _buildConfidenceScore({
    required double avgLast5Scores,
    required double errorRate,
    required int successStreak,
    required int avgResponseTimeMs,
  }) {
    final quality = (avgLast5Scores * 55).round();
    final precision = ((1 - errorRate).clamp(0, 1) * 25).round();
    final consistency = (successStreak.clamp(0, 10) * 1.5).round();
    final speedBonus = avgResponseTimeMs <= 7000 ? 5 : 0;
    return (quality + precision + consistency + speedBonus).clamp(0, 100);
  }

  String _headlineFromScore(int score) {
    if (score >= 80) return 'Excellent rythme - Pret pour des exercices avances';
    if (score >= 60) return 'Bon potentiel - Quelques ajustements pour accelerer';
    return 'Renforcement recommande - Reprendre les bases progressivement';
  }

  String _nextMilestone({
    required int currentLevel,
    required int lessonsCompleted,
    required int successStreak,
  }) {
    if (currentLevel < 3) {
      return 'Atteindre le niveau ${currentLevel + 1} avec 3 reussites consecutives.';
    }
    if (successStreak < 3) {
      return 'Construire un streak de 3 jours pour valider la constance.';
    }
    return 'Maintenir la performance et transferer vers scenarios reels.';
  }
}

