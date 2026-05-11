import 'package:flutter/material.dart';

/// Besoins sélectionnables (libellés stockés dans [Reservation.besoins]).
class ReservationNeedCatalog {
  ReservationNeedCatalog._();

  /// Alias matériel proche « rampe / cheminement » : `Icons.ramp_walking` n’est
  /// pas exposé par `Icons` sur toutes les versions du SDK Flutter.
  static final List<(String label, IconData icon)> entries = [
    ('Accompagnement', Icons.accessibility_new),
    ('Rampe mobile', Icons.follow_the_signs_rounded),
    ('Place réservée', Icons.local_parking),
    ('Interprète LSF', Icons.sign_language),
    ('Alerte audio', Icons.volume_up),
    ('Assistance admin', Icons.assignment_ind),
  ];

  static IconData? iconForLabel(String label) {
    for (final e in entries) {
      if (e.$1 == label) return e.$2;
    }
    return Icons.check_circle_outline;
  }

  /// Remplace une ancienne valeur « Rampe mobile » si nécessaire.
  static IconData iconForStoredNeed(String label) => iconForLabel(label) ?? Icons.widgets_outlined;
}
