import 'package:shared_preferences/shared_preferences.dart';

import '../models/reservation.dart';

/// Stockage local des réservations (clé `"reservations"`, liste JSON).
class ReservationService {
  ReservationService._();

  static const String _prefsKey = 'reservations';

  static Future<void> saveReservation(Reservation r) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getReservations();
    list.add(r);
    await prefs.setString(_prefsKey, Reservation.encodeList(list));
  }

  static Future<List<Reservation>> getReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    return Reservation.decodeList(raw ?? '');
  }

  /// Met le statut à [Reservation.statutAnnulee].
  static Future<void> cancelReservation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getReservations();
    final next = list
        .map((r) => r.id == id
            ? r.copyWith(statut: Reservation.statutAnnulee)
            : r)
        .toList();
    await prefs.setString(_prefsKey, Reservation.encodeList(next));
  }

  /// À venir : pas terminée / annulée, et créneau non passé.
  static Future<List<Reservation>> getUpcoming() async {
    final now = DateTime.now();
    final all = await getReservations();
    return all.where((r) {
      if (r.statut == Reservation.statutAnnulee ||
          r.statut == Reservation.statutTerminee) {
        return false;
      }
      return !r.scheduledAt.isBefore(now);
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Passées : créneau passé, ou statut terminée / annulée.
  static Future<List<Reservation>> getPast() async {
    final now = DateTime.now();
    final all = await getReservations();
    return all
        .where((r) {
          if (r.statut == Reservation.statutAnnulee ||
              r.statut == Reservation.statutTerminee) {
            return true;
          }
          return r.scheduledAt.isBefore(now);
        })
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }
}
