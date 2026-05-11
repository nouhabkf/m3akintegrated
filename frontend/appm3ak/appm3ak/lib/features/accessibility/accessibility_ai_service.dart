// accessibility_ai_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Service Flutter qui appelle le backend FastAPI (Groq + OSM)
// pour obtenir les scores d'accessibilité par type de handicap.
//
// Sources combinées :
//   1. FastAPI — analyse OSM + Groq (port configuré ci-dessous)
//   2. Communauté M3ak — avis agrégés via CommunityPostFetcher (Nest port 3000)
//
// UTILISATION :
//   final result = await AccessibilityAIService.analyze(placeName: ..., latitude: ..., longitude: ...);
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/repositories/community_post_source.dart';

/// URL du backend IA Python (FastAPI). Cible web Chrome : même machine, CORS côté FastAPI.
const String _kBackendUrl = 'http://127.0.0.1:8002';

// ── Modèles ───────────────────────────────────────────────────────────────────

class HandicapScore {
  final int score;
  final String niveau;
  final List<String> details;
  final List<String> sources;

  const HandicapScore({
    required this.score,
    required this.niveau,
    required this.details,
    required this.sources,
  });

  factory HandicapScore.fromJson(Map<String, dynamic> j) => HandicapScore(
        score: (j['score'] as num?)?.toInt() ?? 0,
        niveau: j['niveau'] as String? ?? 'Non adapté',
        details: List<String>.from(j['details'] ?? []),
        sources: List<String>.from(j['sources'] ?? []),
      );

  static const Map<String, int> _colors = {
    'Excellent': 0xFF2A9F58,
    'Bon': 0xFF4A90D9,
    'Partiel': 0xFFE69D2A,
    'Non adapté': 0xFFD24C4C,
  };

  int get color => _colors[niveau] ?? 0xFF888888;
}

class AIAccessibilityResult {
  final String placeName;
  final int scoreGlobal;
  final HandicapScore fauteuilRoulant;
  final HandicapScore surdite;
  final HandicapScore cecite;
  final HandicapScore mobiliteReduite;
  final HandicapScore cognitif;
  final String resumeIA;
  final String confiance;
  final List<String> sourcesUtilisees;
  final Map<String, dynamic> osmTags;

  /// Posts de la communauté utilisés dans l'analyse
  final List<CommunityPostSource> communityPostsUsed;

  const AIAccessibilityResult({
    required this.placeName,
    required this.scoreGlobal,
    required this.fauteuilRoulant,
    required this.surdite,
    required this.cecite,
    required this.mobiliteReduite,
    required this.cognitif,
    required this.resumeIA,
    required this.confiance,
    required this.sourcesUtilisees,
    required this.osmTags,
    this.communityPostsUsed = const [],
  });

  factory AIAccessibilityResult.fromJson(
    Map<String, dynamic> j, {
    List<CommunityPostSource> communityPosts = const [],
  }) {
    Map<String, dynamic> m(dynamic v) =>
        Map<String, dynamic>.from((v as Map?) ?? const {});

    return AIAccessibilityResult(
      placeName: j['place_name'] as String? ?? '',
      scoreGlobal: (j['score_global'] as num?)?.toInt() ?? 0,
      fauteuilRoulant: HandicapScore.fromJson(m(j['fauteuil_roulant'])),
      surdite: HandicapScore.fromJson(m(j['surdite'])),
      cecite: HandicapScore.fromJson(m(j['cecite'])),
      mobiliteReduite: HandicapScore.fromJson(m(j['mobilite_reduite'])),
      cognitif: HandicapScore.fromJson(m(j['cognitif'])),
      resumeIA: j['resume_ia'] as String? ?? '',
      confiance: j['confiance'] as String? ?? 'Faible',
      sourcesUtilisees: List<String>.from(j['sources_utilisees'] ?? []),
      osmTags: j['osm_tags'] as Map<String, dynamic>? ?? {},
      communityPostsUsed: communityPosts,
    );
  }

  HandicapScore scoreFor(String type) {
    switch (type) {
      case 'fauteuil':
        return fauteuilRoulant;
      case 'surdite':
        return surdite;
      case 'cecite':
        return cecite;
      case 'mobilite':
        return mobiliteReduite;
      case 'cognitif':
        return cognitif;
      default:
        return fauteuilRoulant;
    }
  }

  bool get hasCommunitySource => communityPostsUsed.isNotEmpty;
}

// ── Service ───────────────────────────────────────────────────────────────────

class AccessibilityAIService {
  AccessibilityAIService._();

  /// Analyse un lieu et retourne les scores IA.
  static Future<AIAccessibilityResult?> analyze({
    required String placeName,
    required double latitude,
    required double longitude,
    bool wheelchairAccess = false,
    bool elevator = false,
    bool braille = false,
    bool audioAssistance = false,
    bool accessibleToilets = false,
    List<String> userComments = const [],
  }) async {
    final communityPosts =
        await CommunityPostFetcher.fetchPostsForPlace(placeName);

    final communityComments = communityPosts
        .map((p) => '[Communauté M3ak - ${p.typeLabel}] ${p.contenu}')
        .toList();

    final allComments = [...userComments, ...communityComments];

    try {
      final response = await http
          .post(
            Uri.parse('$_kBackendUrl/ai/accessibility/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'place_name': placeName,
              'latitude': latitude,
              'longitude': longitude,
              'wheelchair_access': wheelchairAccess,
              'elevator': elevator,
              'braille': braille,
              'audio_assistance': audioAssistance,
              'accessible_toilets': accessibleToilets,
              'user_comments': allComments,
              'has_community_data': communityPosts.isNotEmpty,
              'community_posts_count': communityPosts.length,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final sources = List<String>.from(data['sources_utilisees'] ?? []);
        if (communityPosts.isNotEmpty && !sources.contains('Communauté M3ak')) {
          sources.add('Communauté M3ak');
          data['sources_utilisees'] = sources;
        }

        return AIAccessibilityResult.fromJson(
          data,
          communityPosts: communityPosts,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isBackendOnline() async {
    try {
      final r = await http
          .get(Uri.parse('$_kBackendUrl/health'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isCommunityBackendOnline() async {
    try {
      final r = await http
          .get(Uri.parse('http://127.0.0.1:3000/community/posts?limit=1'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
