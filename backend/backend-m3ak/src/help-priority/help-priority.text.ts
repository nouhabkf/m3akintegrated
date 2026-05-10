/**
 * Normalisation du texte libre pour la détection de mots-clés (règles métier).
 * Point commun pour les règles actuelles et une future couche ML sur le même texte.
 */
export function normalizeHelpPriorityText(raw: string | null | undefined): string {
  return (raw ?? '').toLowerCase().trim();
}
