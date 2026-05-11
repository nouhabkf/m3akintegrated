import 'package:intl/intl.dart';

/// Formate en français du type : « Samedi 5 avril 2026 à 10h00 ».
/// Exiger [initializeDateFormatting](`fr_FR`) au préalable.
String formatReservationFrenchDateTime(DateTime dt) {
  final raw = DateFormat('EEEE d MMMM y', 'fr_FR').format(dt);
  final head = raw.isEmpty ? raw : raw[0].toUpperCase();
  final tail = raw.length <= 1 ? '' : raw.substring(1);
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$head$tail à ${h}h$m';
}
