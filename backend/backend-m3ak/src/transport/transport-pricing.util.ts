/** Tarification trajet (TND) : base + km + minute — utilisé à la création, à l'estimation et en fin de course. */
export function computeTransportFareTnd(
  distanceKm: number,
  durationMinutes: number,
  config: { base: number; perKm: number; perMinute: number },
): number {
  const raw =
    config.base + distanceKm * config.perKm + durationMinutes * config.perMinute;
  return Math.round(Math.max(0, raw) * 100) / 100;
}
