import 'dart:convert';

/// Réservation d'accès adapté (persistance locale via [shared_preferences]).
class Reservation {
  static const String statutEnAttente = 'en_attente';
  static const String statutConfirmee = 'confirmee';
  static const String statutTerminee = 'terminee';
  static const String statutAnnulee = 'annulee';

  final String id;
  final String placeName;
  /// Date et heure effective de la réservation.
  final DateTime date;
  /// Représentation « HH:mm » (redondante avec [date], utile au JSON demandé).
  final String heure;
  final List<String> besoins;
  final String? note;
  final String statut;
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.placeName,
    required this.date,
    required this.heure,
    required this.besoins,
    required this.note,
    required this.statut,
    required this.createdAt,
  });

  DateTime get scheduledAt => date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeName': placeName,
        'date': date.toIso8601String(),
        'heure': heure,
        'besoins': besoins,
        'note': note,
        'statut': statut,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reservation.fromJson(Map<String, dynamic> j) {
    final dateRaw = j['date'];
    DateTime parsedDate;
    if (dateRaw is String) {
      parsedDate = DateTime.tryParse(dateRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final createdRaw = j['createdAt'];
    DateTime parsedCreated;
    if (createdRaw is String) {
      parsedCreated = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      parsedCreated = DateTime.now();
    }

    final besoinsRaw = j['besoins'];
    final besoinsList = besoinsRaw is List
        ? besoinsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final heureStr = j['heure'] is String ? j['heure'] as String : '';

    return Reservation(
      id: j['id'] as String? ?? '',
      placeName: j['placeName'] as String? ?? '',
      date: parsedDate,
      heure: heureStr,
      besoins: besoinsList,
      note: j['note'] as String?,
      statut: j['statut'] as String? ?? statutConfirmee,
      createdAt: parsedCreated,
    );
  }

  Reservation copyWith({
    String? id,
    String? placeName,
    DateTime? date,
    String? heure,
    List<String>? besoins,
    String? note,
    String? statut,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      placeName: placeName ?? this.placeName,
      date: date ?? this.date,
      heure: heure ?? this.heure,
      besoins: besoins ?? this.besoins,
      note: note ?? this.note,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String encodeList(List<Reservation> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<Reservation> decodeList(String raw) {
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      return decoded
          .map((e) {
            if (e is Map<String, dynamic>) {
              return Reservation.fromJson(e);
            }
            if (e is Map) {
              return Reservation.fromJson(Map<String, dynamic>.from(e));
            }
            return null;
          })
          .whereType<Reservation>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
