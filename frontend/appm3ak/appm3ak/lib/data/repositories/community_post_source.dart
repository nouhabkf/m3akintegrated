// community_post_source.dart
// ─────────────────────────────────────────────────────────────────────────────
// Fetche les posts de la communauté depuis le backend (port 3000)
// et les convertit en source pour le calcul de score IA.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;

// URL du backend communauté (celui de ta collègue)
const String _kCommunityBackendUrl = 'http://127.0.0.1:3000';

const _stopWords = {
  'de', 'la', 'le', 'les', 'des', 'du', 'et', 'en', 'un', 'une', 'aux', 'the',
  'a', 'à', 'au', 'chez', 'pour', 'sur', 'dans', 'ou', 'son', 'sa', 'ses',
};

/// Représente un avis de la communauté utilisé comme source IA
class CommunityPostSource {
  final String postId;
  final String contenu;
  final String type; // handicapMoteur, handicapVisuel, etc.
  final DateTime? createdAt;

  const CommunityPostSource({
    required this.postId,
    required this.contenu,
    required this.type,
    this.createdAt,
  });

  /// Lien de navigation (GoRouter : /post-detail/:id)
  String get routePath => '/post-detail/$postId';

  /// Type lisible
  String get typeLabel {
    switch (type) {
      case 'handicapMoteur':
        return 'Handicap moteur';
      case 'handicapVisuel':
        return 'Handicap visuel';
      case 'handicapAuditif':
        return 'Handicap auditif';
      case 'handicapCognitif':
        return 'Handicap cognitif';
      case 'temoignage':
        return 'Témoignage';
      case 'conseil':
        return 'Conseil';
      default:
        return 'Général';
    }
  }

  /// Extrait court pour l'affichage dans le widget de score
  String get preview {
    if (contenu.length <= 120) return contenu;
    return '${contenu.substring(0, 120)}...';
  }
}

String _foldAccentsLower(String input) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñ';
  const to = 'aaaaaaeeeeiiiiooooouuuuycn';
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.runes) {
    final s = String.fromCharCode(ch);
    if (s == 'œ') {
      buf.write('oe');
      continue;
    }
    if (s == 'æ') {
      buf.write('ae');
      continue;
    }
    final i = from.indexOf(s);
    buf.write(i >= 0 ? to[i] : s);
  }
  return buf.toString();
}

String _slugFromFolded(String folded) {
  final buf = StringBuffer();
  for (final r in folded.runes) {
    final c = String.fromCharCode(r);
    if (c == '_') {
      buf.write('_');
      continue;
    }
    if (RegExp(r'[a-z0-9]').hasMatch(c)) {
      buf.write(c);
    } else {
      buf.write('_');
    }
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

List<String> _significantTokens(String folded) {
  return folded
      .split(RegExp(r'[\s\-_,.;:!?/()\[\]]+'))
      .map((t) => t.trim())
      .where((t) => t.length >= 3 && !_stopWords.contains(t))
      .toList();
}

bool _namesAligned(String aFold, String bFold) {
  if (aFold.isEmpty || bFold.isEmpty) return false;
  if (aFold == bFold) return true;

  final shorter = aFold.length <= bFold.length ? aFold : bFold;
  final longer = aFold.length > bFold.length ? aFold : bFold;

  if (shorter.length >= 12 &&
      longer.contains(shorter) &&
      shorter.split(RegExp(r'\s+')).length >= 2) {
    return true;
  }

  final ta = _significantTokens(shorter);
  final tb = _significantTokens(longer);
  if (ta.isEmpty || tb.isEmpty) return false;

  final cov =
      ta.where((t) => tb.any((u) => u == t || u.contains(t) || t.contains(u))).length;

  if (ta.length <= 3) {
    return cov == ta.length;
  }
  return cov >= (ta.length * 0.66).ceil();
}

bool _placeIdMatchesQuery(String? placeId, String queryFold) {
  if (placeId == null || placeId.isEmpty) return false;
  final slugFold = _slugFromFolded(queryFold);

  if (slugFold.isNotEmpty && slugFold == placeId.toLowerCase()) return true;

  final parts = placeId.split('_').where((p) => p.length >= 3).toList();
  if (parts.isEmpty) return false;
  return parts.every((p) => queryFold.contains(_foldAccentsLower(p)));
}

bool _keywordMatchInContent(String queryFold, String contentFold) {
  final qTok = _significantTokens(queryFold);
  if (qTok.isEmpty) {
    if (queryFold.length >= 3) return contentFold.contains(queryFold);
    return false;
  }

  if (qTok.length == 1) {
    final t = qTok.first;
    if (t.length >= 5) return contentFold.contains(t);
    return false;
  }

  var hits = 0;
  for (final t in qTok) {
    if (contentFold.contains(t)) hits++;
  }
  if (qTok.length == 2) return hits == 2;
  if (qTok.length == 3) return hits >= 2;
  return hits >= (qTok.length * 0.5).ceil() && hits >= 2;
}

/// Correspondance stricte entre le post et le [placeName] demandé.
bool postJsonMatchesPlace(Map<String, dynamic> json, String placeName) {
  final q = _foldAccentsLower(placeName.trim());
  if (q.isEmpty) return false;

  final placeNameField = json['placeName'] as String?;
  final placeText = json['placeText'] as String?;
  for (final field in [placeNameField, placeText]) {
    if (field == null || field.isEmpty) continue;
    if (_namesAligned(q, _foldAccentsLower(field))) return true;
  }

  if (_placeIdMatchesQuery(json['placeId'] as String?, q)) return true;

  final contenu = _foldAccentsLower(json['contenu'] as String? ?? '');
  if (contenu.isEmpty) return false;
  return _keywordMatchInContent(q, contenu);
}

/// Service qui fetche les posts de la communauté
class CommunityPostFetcher {
  CommunityPostFetcher._();

  /// Fetche tous les posts et retourne ceux pertinents pour un lieu/type de handicap
  static Future<List<CommunityPostSource>> fetchPosts({
    String? filterType, // optionnel : filtrer par type de handicap
    int limit = 100,
  }) async {
    try {
      final uri = Uri.parse(
        '$_kCommunityBackendUrl/community/posts?limit=$limit',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final postsList = data['data'] as List? ?? [];

      return postsList
          .map((json) => _parsePost(json as Map<String, dynamic>))
          .where((p) => p != null)
          .cast<CommunityPostSource>()
          .where((p) => filterType == null || p.type == filterType)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetche les posts filtrés par type de handicap
  static Future<List<CommunityPostSource>> fetchPostsForHandicapType(
    String handicapType,
  ) async {
    return fetchPosts(filterType: handicapType);
  }

  /// Fetche TOUS les posts (toutes catégories) pour analyse globale
  static Future<List<CommunityPostSource>> fetchAllPosts() async {
    return fetchPosts();
  }

  /// Posts liés au lieu analysé : priorité placeName/placeText/placeId,
  /// sinon mots-clés discriminants dans le contenu (normalisation sans accents).
  static Future<List<CommunityPostSource>> fetchPostsForPlace(
    String placeName,
  ) async {
    try {
      final uri = Uri.parse(
        '$_kCommunityBackendUrl/community/posts?limit=200',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final postsList = data['data'] as List? ?? [];

      final out = <CommunityPostSource>[];
      for (final raw in postsList) {
        final m = raw as Map<String, dynamic>;
        if (!postJsonMatchesPlace(m, placeName)) continue;
        final p = _parsePost(m);
        if (p != null) out.add(p);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  static CommunityPostSource? _parsePost(Map<String, dynamic> json) {
    try {
      final rawId = json['id'] ?? json['_id'];
      final id = rawId?.toString() ?? '';
      if (id.isEmpty) return null;

      return CommunityPostSource(
        postId: id,
        contenu: json['contenu'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}
