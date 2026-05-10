/**
 * Normalise les numéros tunisiens vers un format cohérent:
 * - retire les espaces/tirets/parenthèses
 * - conserve le préfixe + si présent
 * - 8 chiffres locaux => +216XXXXXXXX
 * - 216XXXXXXXX => +216XXXXXXXX
 */
export function normalizeTunisiaPhone(raw?: string | null): string | null {
  if (!raw) return null;

  const trimmed = raw.trim();
  if (!trimmed) return null;

  const hasPlus = trimmed.startsWith('+');
  let compact = trimmed.replace(/[^\d+]/g, '');
  if (!hasPlus) {
    compact = compact.replace(/\+/g, '');
  } else {
    compact = `+${compact.slice(1).replace(/\+/g, '')}`;
  }

  const digitsOnly = compact.replace(/\D/g, '');

  if (/^\d{8}$/.test(digitsOnly)) {
    return `+216${digitsOnly}`;
  }
  if (/^216\d{8}$/.test(digitsOnly)) {
    return `+${digitsOnly}`;
  }
  if (/^\+216\d{8}$/.test(compact)) {
    return compact;
  }

  // Repli: garder une version compacte pour comparaison cohérente.
  return hasPlus ? `+${digitsOnly}` : digitsOnly;
}
