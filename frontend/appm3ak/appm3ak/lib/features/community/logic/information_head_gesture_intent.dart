/// Détection locale : publication **d’information** courte (souvent photo au parcours tête & yeux).
///
/// Aligné sur des formulations type dataset / tunisien : `info pharmacie accessible now`.
bool isInformationAccessibleInfoHeadGesturePhrase(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.length < 12) return false;

  // Ne pas court-circuiter une demande d’aide explicite.
  if (s.contains('besoin') && s.contains('aide')) return false;
  if (s.contains('demande') && s.contains('aide')) return false;
  if (s.contains('urgence')) return false;

  if (s.startsWith('info ') || s.startsWith('information ')) {
    final rest = s.startsWith('info ')
        ? s.substring(5).trim()
        : s.substring(12).trim();
    if (rest.length < 4) return false;
    return true;
  }

  // Variante tunisienne courante sans espace après "info" mal saisi : rare, on skip.

  return false;
}
