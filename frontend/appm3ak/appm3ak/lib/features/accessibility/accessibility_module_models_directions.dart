part of 'accessibility_module.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Enums & modèles de données (inchangés)
// ═══════════════════════════════════════════════════════════════════════════════
enum DisabilityType { moteur, visuel, auditif, cognitif }
enum PlaceCategory { hopital, administration, cafe, commerce, transport, autre }

PlaceCategory placeCategoryFromJson(String? raw) {
  switch ((raw ?? 'autre').toLowerCase().trim()) {
    case 'hopital':       return PlaceCategory.hopital;
    case 'administration':return PlaceCategory.administration;
    case 'cafe':          return PlaceCategory.cafe;
    case 'commerce':      return PlaceCategory.commerce;
    case 'transport':     return PlaceCategory.transport;
    default:              return PlaceCategory.autre;
  }
}

DisabilityType? disabilityTypeFromJson(String raw) {
  switch (raw.toLowerCase().trim()) {
    case 'moteur':  return DisabilityType.moteur;
    case 'visuel':  return DisabilityType.visuel;
    case 'auditif': return DisabilityType.auditif;
    case 'cognitif':return DisabilityType.cognitif;
    default:        return null;
  }
}

enum ReservationStatus { active, delayed, cancelled, completed }
enum ContributionType  { commentaire, photo, signalement }

class AccessiblePlace {
  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final bool wheelchairAccess;
  final bool elevator;
  final bool braille;
  final bool audioAssistance;
  final bool accessibleToilets;
  final int accessibilityScore;
  final String description;
  final PlaceCategory category;
  final Set<DisabilityType> adaptedFor;
  final double distanceKm;
  final int baseReports;
  final int basePhotos;
  final int? avisTotaux;
  final int? avisRecents;
  final double? moyenne;
  final int? joursDepuisDernierAvis;
  final int? reservationsReussies;
  final int? reservationsTotales;

  const AccessiblePlace({
    required this.id, required this.name, required this.city,
    required this.latitude, required this.longitude,
    required this.wheelchairAccess, required this.elevator,
    required this.braille, required this.audioAssistance,
    required this.accessibleToilets, required this.accessibilityScore,
    required this.description, required this.category,
    required this.adaptedFor, required this.distanceKm,
    required this.baseReports, required this.basePhotos,
    this.avisTotaux, this.avisRecents, this.moyenne,
    this.joursDepuisDernierAvis, this.reservationsReussies,
    this.reservationsTotales,
  });

  static bool   _jsonBool  (Map<String,dynamic> j, String k, [bool   f=false]) { final v=j[k]; return v is bool?v:f; }
  static int    _jsonInt   (Map<String,dynamic> j, String k, int    f) { final v=j[k]; if(v is int)return v; if(v is num)return v.round(); return f; }
  static double _jsonDouble(Map<String,dynamic> j, String k, double f) { final v=j[k]; return v is num?v.toDouble():f; }

  factory AccessiblePlace.fromJson(Map<String,dynamic> json) {
    final adapted = <DisabilityType>{};
    final rawAdapted = json['adaptedFor'];
    if (rawAdapted is List) {
      for (final e in rawAdapted) {
        if (e is String) { final t = disabilityTypeFromJson(e); if (t!=null) adapted.add(t); }
      }
    }
    return AccessiblePlace(
      id: json['id'] as String, name: json['name'] as String,
      city: json['city'] as String? ?? '',
      latitude:  _jsonDouble(json,'latitude', 0), longitude: _jsonDouble(json,'longitude',0),
      wheelchairAccess: _jsonBool(json,'wheelchairAccess'),
      elevator: _jsonBool(json,'elevator'), braille: _jsonBool(json,'braille'),
      audioAssistance: _jsonBool(json,'audioAssistance'),
      accessibleToilets: _jsonBool(json,'accessibleToilets'),
      accessibilityScore: _jsonInt(json,'accessibilityScore',0).clamp(0,100).toInt(),
      description: json['description'] as String? ?? '',
      category: placeCategoryFromJson(json['category'] as String?),
      adaptedFor: adapted,
      distanceKm: _jsonDouble(json,'distanceKm',0),
      baseReports: _jsonInt(json,'baseReports',0),
      basePhotos:  _jsonInt(json,'basePhotos',0),
      avisTotaux:  json['avisTotaux'] as int?,
      avisRecents: json['avisRecents'] as int?,
      moyenne:     (json['moyenne'] as num?)?.toDouble(),
      joursDepuisDernierAvis:  json['joursDepuisDernierAvis'] as int?,
      reservationsReussies:    json['reservationsReussies'] as int?,
      reservationsTotales:     json['reservationsTotales'] as int?,
    );
  }

  static Future<List<AccessiblePlace>> loadFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String,dynamic>) throw const FormatException('JSON racine : objet attendu');
    final list = decoded['places'];
    if (list is! List<dynamic>) throw const FormatException('Clé "places" : tableau attendu');
    return list.map((e) {
      if (e is! Map<String,dynamic>) throw const FormatException('Chaque entrée de "places" doit être un objet');
      return AccessiblePlace.fromJson(e);
    }).toList();
  }
}

class AccessibilityConfidenceResult {
  final double total, recentReviewsScore, reviewConsistencyScore, dataFreshnessScore, reservationReliabilityScore;
  final String confidenceLevel;
  const AccessibilityConfidenceResult({
    required this.total, required this.recentReviewsScore,
    required this.reviewConsistencyScore, required this.dataFreshnessScore,
    required this.reservationReliabilityScore, required this.confidenceLevel,
  });
}

double _safeDivide(num a, num b, [double def=0.0]) { if(b==0||b.isNaN)return def; return(a/b).toDouble(); }

AccessibilityConfidenceResult calculateAccessibilityConfidenceScore(AccessiblePlace place) {
  int at = place.avisTotaux ?? (place.baseReports+place.basePhotos+5);
  int ar = place.avisRecents ?? ((place.baseReports+place.basePhotos)~/2).clamp(0,at);
  double m = place.moyenne ?? (place.accessibilityScore/20.0).clamp(0.0,5.0);
  int j = place.joursDepuisDernierAvis ?? 30;
  int rr = place.reservationsReussies ?? 8;
  int rt = place.reservationsTotales  ?? 10;
  double a = (_safeDivide(ar,at,0)*100).clamp(0.0,100.0);
  double b = m>=4?100.0:(m>=3?70.0:40.0);
  double c = j<=7?100.0:(j<=30?80.0:(j<=90?60.0:30.0));
  double d = (_safeDivide(rr,rt,0)*100).clamp(0.0,100.0);
  double total = (0.30*a+0.25*b+0.20*c+0.25*d).clamp(0.0,100.0);
  String level = total>=80?'High Confidence':(total>=60?'Moderate Confidence':'Low Confidence');
  return AccessibilityConfidenceResult(
    total: total.roundToDouble(), recentReviewsScore: a.roundToDouble(),
    reviewConsistencyScore: b, dataFreshnessScore: c,
    reservationReliabilityScore: d.roundToDouble(), confidenceLevel: level,
  );
}

class ReservationRequest {
  final String id;
  final AccessiblePlace place;
  final DateTime dateTime;
  final List<String> supportNeeds;
  final String note, ticketCode;
  final ReservationStatus status;
  const ReservationRequest({
    required this.id, required this.place, required this.dateTime,
    required this.supportNeeds, required this.note,
    required this.ticketCode, required this.status,
  });
  ReservationRequest copyWith({DateTime? dateTime,ReservationStatus? status,List<String>? supportNeeds,String? note}) =>
    ReservationRequest(id:id,place:place,dateTime:dateTime??this.dateTime,
      supportNeeds:supportNeeds??this.supportNeeds,note:note??this.note,
      ticketCode:ticketCode,status:status??this.status);
}

class UserContribution {
  final String id, placeId, author, message;
  final ContributionType type;
  final DateTime createdAt;
  const UserContribution({required this.id,required this.placeId,required this.author,
    required this.type,required this.message,required this.createdAt});
}

class RoutePlan {
  final String summary, duration, distance;
  final bool avoidObstacles, includesElevator;
  // ── NOUVEAU : source du calcul ──────────────────────────────────────────────
  final RouteSource source;
  final double? aiScore; // score d'accessibilité retourné par votre IA Python
  const RoutePlan({
    required this.summary, required this.duration, required this.distance,
    required this.avoidObstacles, required this.includesElevator,
    this.source = RouteSource.openRoute,
    this.aiScore,
  });
}

/// Indique quelle source a calculé l'itinéraire affiché
enum RouteSource { pythonAI, openRoute }

/// Mode de transport choisi par l'utilisateur
enum TransportMode { apied, voiture, moto }

extension TransportModeExt on TransportMode {
  String get label {
    switch (this) {
      case TransportMode.apied:   return 'À pied';
      case TransportMode.voiture: return 'Voiture';
      case TransportMode.moto:    return 'Moto';
    }
  }
  IconData get icon {
    switch (this) {
      case TransportMode.apied:   return Icons.directions_walk_rounded;
      case TransportMode.voiture: return Icons.directions_car_rounded;
      case TransportMode.moto:    return Icons.two_wheeler_rounded;
    }
  }
  String get osrmProfile {
    switch (this) {
      case TransportMode.apied:   return 'foot';
      case TransportMode.voiture: return 'car';
      case TransportMode.moto:    return 'car';
    }
  }

  /// Profils à tester sur router.project-osrm.org ( GeoJSON dans `routes[0].geometry` ).
  /// Voiture / moto : `driving` comme sur la doc publique, puis `car` si besoin.
  List<String> get osrmProfilesToTry {
    switch (this) {
      case TransportMode.apied:
        return ['foot'];
      case TransportMode.voiture:
      case TransportMode.moto:
        return ['driving', 'car'];
    }
  }
  /// Vitesse moyenne réaliste en km/h (contexte urbain Tunis)
  double get avgSpeedKmh {
    switch (this) {
      case TransportMode.apied:   return 4.5;   // marche normale
      case TransportMode.voiture: return 28.0;  // ville avec feux
      case TransportMode.moto:    return 38.0;  // moto urbaine
    }
  }
  /// Durée estimée en secondes pour une distance en mètres
  double estimateDurationSeconds(double distanceMeters) {
    if (distanceMeters <= 0) return 0;
    return (distanceMeters / 1000.0) / avgSpeedKmh * 3600.0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  OpenRouteDirectionsService (fallback si l'API Python est éteinte)
// ═══════════════════════════════════════════════════════════════════════════════
class OpenRouteDirectionsResult {
  final List<LatLng>? points;
  final double distanceMeters, durationSeconds;
  final String? errorMessage;
  bool get isSuccess => errorMessage==null && points!=null && points!.length>=2;
  const OpenRouteDirectionsResult._({this.points,this.distanceMeters=0,this.durationSeconds=0,this.errorMessage});
  factory OpenRouteDirectionsResult.ok({required List<LatLng> points,required double distanceMeters,required double durationSeconds})
    => OpenRouteDirectionsResult._(points:points,distanceMeters:distanceMeters,durationSeconds:durationSeconds);
  factory OpenRouteDirectionsResult.failure(String message)
    => OpenRouteDirectionsResult._(errorMessage:message);
}

class OpenRouteDirectionsService {
  static const String _apiKey = String.fromEnvironment('OPENROUTESERVICE_API_KEY',defaultValue:'');
  bool get isConfigured => _apiKey.isNotEmpty;
  static const String _host = 'api.openrouteservice.org';

  String _profileForPreferences({required bool preferAccessibleWalking})
    => preferAccessibleWalking ? 'wheelchair' : 'foot-walking';

  String _errorFromDecoded(dynamic decoded) {
    if (decoded is! Map<String,dynamic>) return 'Réponse invalide';
    final err = decoded['error'];
    if (err is String) return err;
    if (err is Map) return err['message']?.toString()??err['code']?.toString()??err.toString();
    return decoded['detail']?.toString()?? 'Erreur API';
  }

  Future<OpenRouteDirectionsResult> fetchRoute({required LatLng start,required LatLng end,required bool preferAccessibleWalking}) async {
    if (!isConfigured) return OpenRouteDirectionsResult.failure('Clé OpenRouteService manquante.');
    final primary = _profileForPreferences(preferAccessibleWalking: preferAccessibleWalking);
    final profiles = preferAccessibleWalking && primary=='wheelchair'
        ? <String>['wheelchair','foot-walking'] : <String>[primary];
    OpenRouteDirectionsResult? lastFailure;
    for (final profile in profiles) {
      final r = await _requestDirectionsProfile(profile:profile,start:start,end:end);
      if (r.isSuccess) return r;
      lastFailure = r;
    }
    return lastFailure ?? OpenRouteDirectionsResult.failure("Échec du calcul d'itinéraire");
  }

  Future<OpenRouteDirectionsResult> _requestDirectionsProfile({required String profile,required LatLng start,required LatLng end}) async {
    final uri = Uri.https(_host,'/v2/directions/$profile/geojson');
    try {
      final response = await http.post(uri,
        headers:{'Authorization':_apiKey,'Content-Type':'application/json; charset=utf-8','Accept':'application/json'},
        body: jsonEncode({'coordinates':[[start.longitude,start.latitude],[end.longitude,end.latitude]]}),
      );
      final dynamic decoded = response.body.isEmpty?null:jsonDecode(response.body);
      if (response.statusCode!=200) {
        return OpenRouteDirectionsResult.failure(decoded is Map<String,dynamic>?_errorFromDecoded(decoded):'HTTP ${response.statusCode}');
      }
      if (decoded is! Map<String,dynamic>) return OpenRouteDirectionsResult.failure('JSON inattendu');
      final features = decoded['features'] as List<dynamic>?;
      if (features==null||features.isEmpty) return OpenRouteDirectionsResult.failure('Aucun tracé');
      final feature  = features.first as Map<String,dynamic>;
      final geometry = feature['geometry'] as Map<String,dynamic>?;
      final rawCoords= geometry?['coordinates'] as List<dynamic>?;
      if (rawCoords==null||rawCoords.isEmpty) return OpenRouteDirectionsResult.failure('Géométrie absente');
      final points = <LatLng>[];
      for (final item in rawCoords) {
        if (item is List && item.length>=2) points.add(LatLng((item[1] as num).toDouble(),(item[0] as num).toDouble()));
      }
      if (points.length<2) return OpenRouteDirectionsResult.failure('Tracé insuffisant');
      double distM=0, durS=0;
      final props = feature['properties'] as Map<String,dynamic>?;
      final summary = props?['summary'] as Map<String,dynamic>?;
      if (summary!=null) { distM=(summary['distance'] as num?)?.toDouble()??0; durS=(summary['duration'] as num?)?.toDouble()??0; }
      return OpenRouteDirectionsResult.ok(points:points,distanceMeters:distM,durationSeconds:durS);
    } on FormatException catch(e) {
      return OpenRouteDirectionsResult.failure('JSON invalide: ${e.message}');
    } catch(e) {
      return OpenRouteDirectionsResult.failure('Erreur réseau: $e');
    }
  }
}

String _formatRouteDuration(double seconds) {
  if (seconds<=0) return '—';
  final m=(seconds/60).ceil();
  if (m>=60) { final h=m~/60; final rm=m%60; return '$h h $rm min'; }
  return '$m min';
}
String _formatRouteDistance(double meters) {
  if (meters<=0) return '—';
  if (meters<1000) return '${meters.round()} m';
  return '${(meters/1000).toStringAsFixed(1)} km';
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GeoapifyPlacesService (inchangé)
// ═══════════════════════════════════════════════════════════════════════════════
class PlaceGeoInsights {
  final String sourceName;
  final List<String> photoUrls;
  final int issueSignals;
  final String? error;
  const PlaceGeoInsights({required this.sourceName,required this.photoUrls,required this.issueSignals,this.error});
}

// ═══════════════════════════════════════════════════════════════════════════════
//  OsrmDirectionsService — gratuit, sans clé API
//  Stratégie multi-proxy pour Chrome/Web :
//    1. OSRM direct (mobile/desktop)
//    2. OSRM via allorigins.win  (web — proxy stable)
//    3. OSRM via corsproxy.io   (web — backup)
//    4. OSRM via api.allorigins.win/raw (web — backup 2)
//    5. Valhalla / Stadia Maps  (web — CORS natif, gratuit sans clé)
// ═══════════════════════════════════════════════════════════════════════════════
class OsrmDirectionsService {
  static const String _host = 'router.project-osrm.org';

  static Map<String, String> get _osrmQueryParams => const {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
        'continue_straight': 'false',
      };

  /// URL complète HTTPS (pour proxies web) :
  /// `/route/v1/{profile}/{lon1},{lat1};{lon2},{lat2}?overview=full&geometries=geojson`
  static String _osrmDirectUrl(String profile, String coords) {
    final q = Uri(queryParameters: _osrmQueryParams).query;
    return 'https://$_host/route/v1/$profile/$coords?$q';
  }

  // ── Essai d'un URL (direct ou proxy) — retourne null si echec ─────────────
  static Future<OpenRouteDirectionsResult?> _tryOsrmUrl(Uri uri) async {
    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'M3akApp/2.0'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      // allorigins wraps the body in {"contents": "..."}
      dynamic body = jsonDecode(response.body);
      if (body is Map && body.containsKey('contents')) {
        body = jsonDecode(body['contents'] as String);
      }
      if (body is! Map<String, dynamic>) return null;

      final code = body['code'] as String?;
      if (code != 'Ok') return null;

      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route    = routes.first as Map<String, dynamic>;
      final distM    = (route['distance'] as num?)?.toDouble() ?? 0;
      final durS     = (route['duration'] as num?)?.toDouble() ?? 0;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final rawCoords = geometry?['coordinates'] as List<dynamic>?;
      if (rawCoords == null || rawCoords.isEmpty) return null;

      final points = <LatLng>[];
      for (final item in rawCoords) {
        if (item is List && item.length >= 2) {
          points.add(LatLng(
            (item[1] as num).toDouble(),
            (item[0] as num).toDouble(),
          ));
        }
      }
      if (points.length < 2) return null;
      return OpenRouteDirectionsResult.ok(
          points: points, distanceMeters: distM, durationSeconds: durS);
    } catch (_) {
      return null;
    }
  }

  // ── Fallback : Valhalla public (CORS OK, sans clé, vrai tracé OSM) ─────────
  static Future<OpenRouteDirectionsResult?> _tryValhalla({
    required LatLng start,
    required LatLng end,
    required TransportMode mode,
  }) async {
    // costing: pedestrian / auto / motorcycle
    final costing = switch (mode) {
      TransportMode.apied   => 'pedestrian',
      TransportMode.voiture => 'auto',
      TransportMode.moto    => 'motorcycle',
    };
    final body = jsonEncode({
      'locations': [
        {'lon': start.longitude, 'lat': start.latitude},
        {'lon': end.longitude,   'lat': end.latitude},
      ],
      'costing': costing,
      'shape_match': 'map_snap',
      'directions_options': {'units': 'km'},
    });
    try {
      // valhalla.openstreetmap.de — public, CORS activé
      final uri = Uri.parse('https://valhalla1.openstreetmap.de/route');
      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: body)
          .timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final trip    = decoded['trip'] as Map<String, dynamic>?;
      if (trip == null) return null;

      final legs = trip['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;

      // Valhalla retourne la géométrie encodée en polyline6
      final allPoints = <LatLng>[];
      double totalDistM = 0, totalDurS = 0;

      for (final leg in legs) {
        final l = leg as Map<String, dynamic>;
        final summary = l['summary'] as Map<String, dynamic>?;
        totalDistM += ((summary?['length'] as num?)?.toDouble() ?? 0) * 1000;
        totalDurS  += (summary?['time'] as num?)?.toDouble() ?? 0;
        final shapeStr = l['shape'] as String?;
        if (shapeStr != null) {
          allPoints.addAll(_decodePolyline6(shapeStr));
        }
      }
      if (allPoints.length < 2) return null;
      return OpenRouteDirectionsResult.ok(
          points: allPoints,
          distanceMeters: totalDistM,
          durationSeconds: totalDurS);
    } catch (_) {
      return null;
    }
  }

  // ── Décodeur polyline6 (précision 1e-6 comme Valhalla) ────────────────────
  static List<LatLng> _decodePolyline6(String encoded) {
    final result = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result0 = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lat += dlat;

      shift = 0; result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lng += dlng;

      result.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return result;
  }

  Future<OpenRouteDirectionsResult?> _tryOsrmWebProxies(String directUrl) async {
    final p1 = Uri.parse(
        'https://api.allorigins.win/get?url=${Uri.encodeComponent(directUrl)}');
    final r1 = await _tryOsrmUrl(p1);
    if (r1 != null) return r1;

    final p2 = Uri.parse(
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(directUrl)}');
    final r2 = await _tryOsrmUrl(p2);
    if (r2 != null) return r2;

    final p3 = Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(directUrl)}');
    final r3 = await _tryOsrmUrl(p3);
    return r3;
  }

  // ── Point d'entrée principal ───────────────────────────────────────────────
  Future<OpenRouteDirectionsResult> fetchRoute({
    required LatLng start,
    required LatLng end,
    required TransportMode mode,
  }) async {
    final coords = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final profiles = mode.osrmProfilesToTry;

    for (final profile in profiles) {
      final directUrl = _osrmDirectUrl(profile, coords);

      if (!kIsWeb) {
        final uri = Uri.https(
          _host,
          '/route/v1/$profile/$coords',
          _osrmQueryParams,
        );
        final r = await _tryOsrmUrl(uri);
        if (r != null) {
          debugPrint(
              '[OSRM] ✅ Direct OK (profile=$profile) — ${r.points!.length} pts — GeoJSON geometry');
          return r;
        }
        debugPrint('[OSRM] Direct KO profile=$profile');
      } else {
        final viaProxy = await _tryOsrmWebProxies(directUrl);
        if (viaProxy != null) {
          debugPrint(
              '[OSRM] ✅ Proxy OK (profile=$profile) — ${viaProxy.points!.length} pts');
          return viaProxy;
        }
        debugPrint('[OSRM] Proxies KO profile=$profile');
      }
    }

    debugPrint('[OSRM] Tous les profils OSRM KO — Valhalla');

    // ── Dernier recours : Valhalla (CORS natif, gratuit, vrai tracé OSM) ────
    final vr = await _tryValhalla(start: start, end: end, mode: mode);
    if (vr != null) {
      debugPrint('[OSRM] ✅ Valhalla OK — ${vr.points!.length} pts');
      return vr;
    }
    debugPrint('[OSRM] ❌ Tous les moteurs ont échoué');
    return OpenRouteDirectionsResult.failure(
        'Impossible de calculer un tracé réel (OSRM + Valhalla indisponibles).');
  }
}

class GeoapifyPlacesService {
  static const String _apiKey = String.fromEnvironment('GEOAPIFY_API_KEY',defaultValue:'91aee5d0e30f41a0aabf751d953dece3');
  bool get isEnabled => _apiKey.isNotEmpty;

  Future<PlaceGeoInsights?> fetchInsights({required AccessiblePlace place,required String category,required int radiusMeters}) async {
    if (!isEnabled) return null;
    try {
      final geocodeUri = Uri.https('api.geoapify.com','/v1/geocode/search',
        {'text':'${place.name}, ${place.city}, Tunisia','lang':'fr','limit':'1','apiKey':_apiKey});
      final geocodeResp = await http.get(geocodeUri);
      if (geocodeResp.statusCode!=200) return const PlaceGeoInsights(sourceName:'Geoapify Places',photoUrls:[],issueSignals:0,error:'Echec geocodage');
      final geocodeJson = jsonDecode(geocodeResp.body) as Map<String,dynamic>;
      final geocodeFeatures = (geocodeJson['features'] as List<dynamic>?)??[];
      if (geocodeFeatures.isEmpty) return const PlaceGeoInsights(sourceName:'Geoapify Places',photoUrls:[],issueSignals:0,error:'Aucun point geocode');
      final firstFeature = geocodeFeatures.first as Map<String,dynamic>;
      final geometry = (firstFeature['geometry'] as Map<String,dynamic>?)??{};
      final coordinates = (geometry['coordinates'] as List<dynamic>?)??[];
      if (coordinates.length<2) return const PlaceGeoInsights(sourceName:'Geoapify Places',photoUrls:[],issueSignals:0,error:'Coordonnees invalides');
      final lon=(coordinates[0] as num).toDouble(); final lat=(coordinates[1] as num).toDouble();
      final placesUri = Uri.https('api.geoapify.com','/v2/places',
        {'categories':category,'filter':'circle:$lon,$lat,$radiusMeters','bias':'proximity:$lon,$lat','limit':'20','apiKey':_apiKey});
      final placesResp = await http.get(placesUri);
      if (placesResp.statusCode!=200) return const PlaceGeoInsights(sourceName:'Geoapify Places',photoUrls:[],issueSignals:0,error:'Echec recherche places');
      final placesJson = jsonDecode(placesResp.body) as Map<String,dynamic>;
      final features = (placesJson['features'] as List<dynamic>?)??[];
      if (features.isEmpty) return const PlaceGeoInsights(sourceName:'Geoapify Places',photoUrls:[],issueSignals:0,error:'Aucun lieu trouve');
      final featureMaps = features.cast<Map<String,dynamic>>();
      featureMaps.sort((a,b) {
        final ap=(a['properties'] as Map<String,dynamic>?)??{}; final bp=(b['properties'] as Map<String,dynamic>?)??{};
        final an=((ap['name'] as String?)??'').toLowerCase(); final bn=((bp['name'] as String?)??'').toLowerCase();
        final target=place.name.toLowerCase();
        return _matchScore(bn,target).compareTo(_matchScore(an,target));
      });
      final bestProps=(featureMaps.first['properties'] as Map<String,dynamic>?)??{};
      final sourceName=(bestProps['name'] as String?)??place.name;
      final photoUrls=<String>{}; int issueSignals=0;
      for (final feature in featureMaps) {
        final props=(feature['properties'] as Map<String,dynamic>?)??{};
        final datasource=(props['datasource'] as Map<String,dynamic>?)??{};
        final raw=(datasource['raw'] as Map<String,dynamic>?)??{};
        final image=props['image']; if(image is String&&image.startsWith('http')) photoUrls.add(image);
        final rawImage=raw['image']; if(rawImage is String&&rawImage.startsWith('http')) photoUrls.add(rawImage);
        final wikimedia=raw['wikimedia_commons'];
        if(wikimedia is String&&wikimedia.startsWith('File:')) photoUrls.add('https://commons.wikimedia.org/wiki/Special:FilePath/${wikimedia.replaceFirst('File:','')}');
        final wheelchair=(raw['wheelchair']??props['wheelchair'])?.toString().toLowerCase();
        final access=(raw['access']??'').toString().toLowerCase();
        if(wheelchair=='no'||wheelchair=='limited'||access=='private') issueSignals++;
      }
      return PlaceGeoInsights(sourceName:sourceName,photoUrls:photoUrls.take(6).toList(),issueSignals:issueSignals);
    } catch(_) {
      return const PlaceGeoInsights(sourceName:'Geoapify Places',photoUrls:[],issueSignals:0,error:'Erreur de recuperation');
    }
  }
  int _matchScore(String candidate,String query) {
    if(candidate==query) return 3; if(candidate.contains(query)) return 2;
    if(query.split(' ').any(candidate.contains)) return 1; return 0;
  }
}
