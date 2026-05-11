/// Dérive le champ API `type` (enum existante) à partir des sélecteurs inclusifs.
///
/// Rétrocompatible avec les filtres « smart » et l’historique MongoDB.
String legacyPostTypeFromInclusive({
  required String postNature,
  required String targetAudience,
}) {
  switch (postNature) {
    case 'conseil':
      return 'conseil';
    case 'temoignage':
      return 'temoignage';
    default:
      switch (targetAudience) {
        case 'motor':
          return 'handicapMoteur';
        case 'visual':
          return 'handicapVisuel';
        case 'hearing':
          return 'handicapAuditif';
        case 'cognitive':
          return 'handicapCognitif';
        case 'all':
        case 'caregiver':
          return 'general';
        default:
          return 'general';
      }
  }
}
