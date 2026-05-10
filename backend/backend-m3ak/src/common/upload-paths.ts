import { join } from 'path';

/**
 * Dossier absolu des fichiers uploadés.
 * Multer (`destination`) et `app.useStaticAssets` doivent utiliser exactement ce chemin,
 * sinon les fichiers sont écrits à un endroit et servis depuis un autre → 404 sur `/uploads/...`.
 */
export function getUploadsRoot(): string {
  return join(process.cwd(), 'uploads');
}

/** Préfixe logique en base et dans les URLs publiques (`uploads/nom-fichier`). */
export const UPLOADS_PUBLIC_PREFIX = 'uploads';
