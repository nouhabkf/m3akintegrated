import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  AccessibleRouteResult
//  Champs distanceMeters / durationSeconds ajoutés pour main.dart
// ═══════════════════════════════════════════════════════════════════════════════
class AccessibleRouteResult {
  final List<LatLng> coordinates;
  final List<int> bestPath;
  final double accessibilityScore;
  final String? errorMessage;
  // ── NOUVEAUX champs utilisés par main.dart ──────────────────────────────────
  final double distanceMeters;
  final double durationSeconds;

  bool get isSuccess => errorMessage == null && coordinates.length >= 2;

  const AccessibleRouteResult._({
    this.coordinates = const [],
    this.bestPath = const [],
    this.accessibilityScore = 0,
    this.errorMessage,
    this.distanceMeters = 0,
    this.durationSeconds = 0,
  });

  factory AccessibleRouteResult.ok({
    required List<LatLng> coordinates,
    required List<int> bestPath,
    required double accessibilityScore,
    double distanceMeters = 0,
    double durationSeconds = 0,
  }) {
    return AccessibleRouteResult._(
      coordinates: coordinates,
      bestPath: bestPath,
      accessibilityScore: accessibilityScore,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  factory AccessibleRouteResult.failure(String message) {
    return AccessibleRouteResult._(errorMessage: message);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AccessibleRouteService
//  Stratégie :
//    1. API Python A* + DL (priorité absolue)
//    2. OSRM walking (fallback si Python éteint) → VRAI tracé routier
//  Dans les deux cas : distanceMeters et durationSeconds sont calculés
//  sur le tracé réel retourné (pas une ligne droite).
// ═══════════════════════════════════════════════════════════════════════════════
class AccessibleRouteService {
  static String? _resolvedBaseUrl;
  static bool get wasReachableAtStartup => _reachableAtStartupFlag ?? false;
  static bool? _reachableAtStartupFlag;

  static const String _osrmHost = 'router.project-osrm.org';

  // ── Initialisation (à appeler dans main()) ───────────────────────────────
  static Future<void> preloadEndpointFromAsset({
    bool resetReachableFlag = true,
  }) async {
    if (resetReachableFlag) _reachableAtStartupFlag = false;

    const fromEnv = String.fromEnvironment(
      'PY_ROUTE_API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) {
      final u = fromEnv.replaceAll(RegExp(r'/+$'), '');
      if (await _healthOk(u)) {
        _resolvedBaseUrl = u;
        _reachableAtStartupFlag = true;
        debugPrint('[AI ROUTE] API joignable (dart-define) → $u');
        return;
      }
    }

    final fromFile = await _urlsFromAssetFile();
    final tried = <String>{};
    for (final u in fromFile) {
      if (!tried.add(u)) continue;
      if (await _healthOk(u)) {
        _resolvedBaseUrl = u;
        _reachableAtStartupFlag = true;
        debugPrint('[AI ROUTE] API joignable (fichier) → $u');
        return;
      }
    }
    for (final u in _platformFallbackUrls()) {
      if (!tried.add(u)) continue;
      if (await _healthOk(u)) {
        _resolvedBaseUrl = u;
        _reachableAtStartupFlag = true;
        debugPrint('[AI ROUTE] API joignable (fallback) → $u');
        return;
      }
    }

    _resolvedBaseUrl = fromFile.isNotEmpty
        ? fromFile.first
        : _singlePlatformDefault();
    debugPrint('[AI ROUTE] Aucune API joignable — défaut : $_resolvedBaseUrl');
  }

  static Future<List<String>> _urlsFromAssetFile() async {
    final out = <String>[];
    try {
      final raw = await rootBundle.loadString('assets/ai_api_endpoint.txt');
      for (final line in raw.split(RegExp(r'\r?\n'))) {
        final t = line.trim();
        if (t.isEmpty || t.startsWith('#')) continue;
        if (t.startsWith('http')) out.add(t.replaceAll(RegExp(r'/+$'), ''));
      }
    } catch (e) {
      debugPrint('[AI ROUTE] ai_api_endpoint.txt : $e');
    }
    return out;
  }

  static List<String> _platformFallbackUrls() {
    if (kIsWeb) return ['http://127.0.0.1:8000', 'http://localhost:8000'];
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return ['http://10.0.2.2:8000', 'http://127.0.0.1:8000'];
      default:
        return ['http://127.0.0.1:8000', 'http://localhost:8000'];
    }
  }

  static String _singlePlatformDefault() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static Future<bool> _healthOk(String base) async {
    try {
      final uri = Uri.parse('$base/health');
      final r = await http.get(uri).timeout(const Duration(seconds: 4));
      if (r.statusCode != 200) return false;
      final data = jsonDecode(r.body);
      if (data is Map<String, dynamic>) return data['ok'] == true;
      return false;
    } catch (e) {
      debugPrint('[AI ROUTE] /health échec $base — $e');
      return false;
    }
  }

  static String get _baseUrl {
    const fromEnv = String.fromEnvironment(
      'PY_ROUTE_API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/+$'), '');
    final r = _resolvedBaseUrl?.trim();
    if (r != null && r.isNotEmpty) return r;
    return _singlePlatformDefault();
  }

  static const Duration _timeout = Duration(seconds: 15);

  // ── Parseurs (identiques à l'original) ──────────────────────────────────
  List<LatLng> _parseCoordinates(Map<String, dynamic> data) {
    final dynamic coordsSource =
        data['coordinates'] ??
        data['path_coordinates'] ??
        data['route_coordinates'] ??
        data['route'] ??
        data['path'];

    if (coordsSource is! List) return const [];
    final parsed = <LatLng>[];

    for (final item in coordsSource) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final latRaw = m['lat'] ?? m['latitude'] ?? m['y'];
        final lonRaw = m['lon'] ?? m['lng'] ?? m['longitude'] ?? m['x'];
        if (latRaw is num && lonRaw is num) {
          parsed.add(LatLng(latRaw.toDouble(), lonRaw.toDouble()));
        }
        continue;
      }
      if (item is List && item.length >= 2) {
        final a = item[0];
        final b = item[1];
        if (a is num && b is num) {
          final looksLikeLatLon = a.abs() <= 90 && b.abs() > 90;
          final lat = looksLikeLatLon ? a.toDouble() : b.toDouble();
          final lon = looksLikeLatLon ? b.toDouble() : a.toDouble();
          parsed.add(LatLng(lat, lon));
        }
      }
    }
    return parsed;
  }

  List<int> _parseBestPath(Map<String, dynamic> data) {
    final raw = data['best_path'] ?? data['path_nodes'] ?? data['nodes'];
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is int) return e;
          if (e is num) return e.toInt();
          if (e is String) return int.tryParse(e);
          return null;
        })
        .whereType<int>()
        .toList();
  }

  double _parseAccessibilityScore(Map<String, dynamic> data) {
    final raw = data['average_accessibility_score'] ??
        data['accessibility_score'] ??
        data['ai_score'] ??
        data['score'];
    if (raw is! num) return 0.0;
    final value = raw.toDouble();
    if (value > 1.0) return (value / 100).clamp(0.0, 1.0);
    return value.clamp(0.0, 1.0);
  }

  Future<int?> getNearestNode(double lat, double lon) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/nearest_node'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'lat': lat, 'lon': lon}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('[AI ROUTE] nearest_node HTTP ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final id = data['node_id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
      if (id is String) return int.tryParse(id);
      return null;
    } catch (e) {
      debugPrint('[AI ROUTE] nearest_node erreur : $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  fetchAccessibleRoute
  //  Priorité 1 → API Python A* + DL
  //  Priorité 2 → OSRM foot (tracé réel sur les rues OSM)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<AccessibleRouteResult> fetchAccessibleRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    debugPrint('[AI ROUTE] baseUrl=$_baseUrl');

    // ── Tentative 1 : API Python ────────────────────────────────────────────
    if (await _healthOk(_baseUrl)) {
      final result = await _fetchFromPythonApi(start: start, end: end);
      if (result.isSuccess) {
        debugPrint('[AI ROUTE] ✅ Python A* OK — ${result.coordinates.length} pts, score=${result.accessibilityScore}');
        return result;
      }
      debugPrint('[AI ROUTE] Python A* KO: ${result.errorMessage}');
    } else {
      // Nouvelle tentative de résolution d'URL
      await preloadEndpointFromAsset(resetReachableFlag: false);
      if (await _healthOk(_baseUrl)) {
        _reachableAtStartupFlag = true;
        final result = await _fetchFromPythonApi(start: start, end: end);
        if (result.isSuccess) return result;
      }
      debugPrint('[AI ROUTE] API Python inaccessible — fallback OSRM');
    }

    // ── Tentative 2 : OSRM (vrai tracé routier, aucune clé requise) ─────────
    return _fetchFromOsrm(start: start, end: end);
  }

  // ── Appel API Python ───────────────────────────────────────────────────────
  Future<AccessibleRouteResult> _fetchFromPythonApi({
    required LatLng start,
    required LatLng end,
  }) async {
    final startNode = await getNearestNode(start.latitude, start.longitude);
    if (startNode == null) {
      return AccessibleRouteResult.failure(
        'Nœud de départ introuvable — API Python démarrée ?',
      );
    }
    final endNode = await getNearestNode(end.latitude, end.longitude);
    if (endNode == null) {
      return AccessibleRouteResult.failure('Nœud de destination introuvable.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/accessible_route_full'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'start_node': startNode, 'end_node': endNode}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return AccessibleRouteResult.failure(
          'Erreur serveur Python : HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error')) {
        return AccessibleRouteResult.failure(data['error'] as String);
      }

      final coords = _parseCoordinates(data);
      if (coords.length < 2) {
        return AccessibleRouteResult.failure('Coordonnées IA invalides.');
      }

      final bestPath = _parseBestPath(data);
      final score = _parseAccessibilityScore(data);

      // Calcul de la distance réelle sur le tracé IA
      double distMeters = 0;
      for (int i = 0; i < coords.length - 1; i++) {
        distMeters += const Distance().as(LengthUnit.Meter, coords[i], coords[i + 1]);
      }

      // Durée piéton OSRM-like : 4.5 km/h
      final durSeconds = distMeters / 1000.0 / 4.5 * 3600.0;

      return AccessibleRouteResult.ok(
        coordinates: coords,
        bestPath: bestPath,
        accessibilityScore: score,
        distanceMeters: distMeters,
        durationSeconds: durSeconds,
      );
    } catch (e) {
      return AccessibleRouteResult.failure('Erreur réseau Python : $e');
    }
  }

  // ── Fallback OSRM / Valhalla : vrai tracé routier OSM ────────────────────
  //  Stratégie :
  //    1. OSRM direct          (mobile/desktop — pas de CORS)
  //    2. allorigins.win/get   (web — proxy stable, wraps JSON)
  //    3. allorigins.win/raw   (web — backup)
  //    4. corsproxy.io         (web — backup 2)
  //    5. Valhalla openstreetmap.de (CORS natif, gratuit, vrai tracé OSM)
  Future<AccessibleRouteResult> _fetchFromOsrm({
    required LatLng start,
    required LatLng end,
  }) async {
    final coords = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final directUrl =
        'https://router.project-osrm.org/route/v1/foot/$coords'
        '?overview=full&geometries=geojson&steps=false';

    List<LatLng>? points;
    double distM = 0, durS = 0;

    if (!kIsWeb) {
      // ── Mobile / Desktop : OSRM direct ────────────────────────────────────
      final r = await _tryOsrmUrl(Uri.https(
        _osrmHost, '/route/v1/foot/$coords',
        {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
      ));
      if (r != null) { points = r.$1; distM = r.$2; durS = r.$3; }
    } else {
      // ── Web : cascade de proxies CORS ─────────────────────────────────────
      // Proxy 1 — allorigins.win/get (wraps body in {contents:...})
      var r = await _tryOsrmUrl(Uri.parse(
          'https://api.allorigins.win/get?url=${Uri.encodeComponent(directUrl)}'));
      r ??= await _tryOsrmUrl(Uri.parse(
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(directUrl)}'));
      r ??= await _tryOsrmUrl(Uri.parse(
          'https://corsproxy.io/?${Uri.encodeComponent(directUrl)}'));
      if (r != null) { points = r.$1; distM = r.$2; durS = r.$3; }
    }

    // ── Valhalla fallback (CORS natif, pédestre) ───────────────────────────
    if (points == null || points.length < 2) {
      final vr = await _tryValhallaPedestrian(start: start, end: end);
      if (vr != null) { points = vr.$1; distM = vr.$2; durS = vr.$3; }
    }

    if (points == null || points.length < 2) {
      return AccessibleRouteResult.failure(
          'Impossible d\'obtenir un tracé réel (OSRM + Valhalla indisponibles).');
    }

    debugPrint('[AI ROUTE] ✅ OSRM/Valhalla fallback OK — ${points.length} pts, dist=${distM.toInt()}m');

    final score = _computeAccessibilityScore(
        points: points, distanceMeters: distM, start: start, end: end);

    return AccessibleRouteResult.ok(
      coordinates: points,
      bestPath: const [],
      accessibilityScore: score,
      distanceMeters: distM,
      durationSeconds: durS,
    );
  }

  // ── Essai d'une URI OSRM — retourne (points, distM, durS) ou null ─────────
  static Future<(List<LatLng>, double, double)?> _tryOsrmUrl(Uri uri) async {
    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'M3akAccessibilityApp/2.0'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      dynamic body = jsonDecode(response.body);
      // allorigins.win/get wraps in {contents: "..."}
      if (body is Map && body.containsKey('contents')) {
        body = jsonDecode(body['contents'] as String);
      }
      if (body is! Map<String, dynamic>) return null;
      if ((body['code'] as String?) != 'Ok') return null;

      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route     = routes.first as Map<String, dynamic>;
      final distM     = (route['distance'] as num?)?.toDouble() ?? 0;
      final durS      = (route['duration'] as num?)?.toDouble() ?? 0;
      final geometry  = route['geometry'] as Map<String, dynamic>?;
      final rawCoords = geometry?['coordinates'] as List<dynamic>?;
      if (rawCoords == null || rawCoords.isEmpty) return null;

      final pts = <LatLng>[];
      for (final item in rawCoords) {
        if (item is List && item.length >= 2) {
          pts.add(LatLng((item[1] as num).toDouble(), (item[0] as num).toDouble()));
        }
      }
      if (pts.length < 2) return null;
      return (pts, distM, durS);
    } catch (_) {
      return null;
    }
  }

  // ── Valhalla public (valhalla1.openstreetmap.de) — CORS natif ─────────────
  static Future<(List<LatLng>, double, double)?> _tryValhallaPedestrian({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final body = jsonEncode({
        'locations': [
          {'lon': start.longitude, 'lat': start.latitude},
          {'lon': end.longitude,   'lat': end.latitude},
        ],
        'costing': 'pedestrian',
        'directions_options': {'units': 'km'},
      });
      final uri = Uri.parse('https://valhalla1.openstreetmap.de/route');
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final trip    = decoded['trip'] as Map<String, dynamic>?;
      if (trip == null) return null;
      final legs    = trip['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;

      final pts = <LatLng>[];
      double totalDistM = 0, totalDurS = 0;
      for (final leg in legs) {
        final l       = leg as Map<String, dynamic>;
        final summary = l['summary'] as Map<String, dynamic>?;
        totalDistM += ((summary?['length'] as num?)?.toDouble() ?? 0) * 1000;
        totalDurS  += (summary?['time']   as num?)?.toDouble() ?? 0;
        final shapeStr = l['shape'] as String?;
        if (shapeStr != null) pts.addAll(_decodePolyline6(shapeStr));
      }
      if (pts.length < 2) return null;
      return (pts, totalDistM, totalDurS);
    } catch (_) {
      return null;
    }
  }

  // ── Décodeur polyline6 (précision 1e-6, format Valhalla) ──────────────────
  static List<LatLng> _decodePolyline6(String encoded) {
    final result = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, res = 0, b;
      do { b = encoded.codeUnitAt(index++) - 63; res |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lat += (res & 1) != 0 ? ~(res >> 1) : (res >> 1);
      shift = 0; res = 0;
      do { b = encoded.codeUnitAt(index++) - 63; res |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lng += (res & 1) != 0 ? ~(res >> 1) : (res >> 1);
      result.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return result;
  }

  // ── Score accessibilité heuristique (quand l'IA Python est indisponible) ──
  // Basé sur : ratio détour, régularité angulaire, longueur
  double _computeAccessibilityScore({
    required List<LatLng> points,
    required double distanceMeters,
    required LatLng start,
    required LatLng end,
  }) {
    if (distanceMeters <= 0) return 0.5;

    final straightLine = const Distance().as(LengthUnit.Meter, start, end);
    final detourRatio = straightLine > 0
        ? (straightLine / distanceMeters).clamp(0.0, 1.0)
        : 0.5;

    double angleVariance = 0;
    if (points.length >= 3) {
      final angles = <double>[];
      for (int i = 1; i < points.length - 1; i++) {
        final a = _bearing(points[i - 1], points[i]);
        final b = _bearing(points[i], points[i + 1]);
        angles.add((b - a).abs() % 360);
      }
      final mean = angles.reduce((a, b) => a + b) / angles.length;
      angleVariance = angles
          .map((a) => math.pow(a - mean, 2).toDouble())
          .reduce((a, b) => a + b) / angles.length;
    }
    final regularityScore = (1.0 - (angleVariance / 10000.0).clamp(0.0, 1.0));

    final lengthScore = distanceMeters < 500
        ? 1.0
        : distanceMeters < 2000
            ? 0.85
            : distanceMeters < 5000
                ? 0.70
                : 0.55;

    return (0.40 * detourRatio + 0.30 * regularityScore + 0.30 * lengthScore)
        .clamp(0.0, 1.0);
  }

  double _bearing(LatLng a, LatLng b) {
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x) * 180 / math.pi;
  }

  double _deg2rad(double deg) => deg * math.pi / 180;
}
