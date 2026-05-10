/** Bbox approximative Grand Tunis (Tunis, Ariana, Ben Arous, Manouba) — sud, ouest, nord, est */
export const GRAND_TUNIS_BBOX = {
  south: 36.68,
  west: 10.02,
  north: 36.93,
  east: 10.35,
} as const;

/** Limite max de résultats renvoyés au client (après réception Overpass) */
export const PLACES_MAX_LIMIT = 2000;
export const PLACES_DEFAULT_LIMIT = 500;

/** Écart max autorisé (degrés) pour éviter des requêtes sur toute la Tunisie */
export const PLACES_MAX_LAT_SPAN = 0.55;
export const PLACES_MAX_LON_SPAN = 0.55;

export type OsmPlaceFilter =
  | { kind: 'amenity'; value: string }
  | { kind: 'shop_any' }
  | { kind: 'shop'; value: string }
  | { kind: 'tourism'; value: string };

/**
 * Jetons acceptés en query `categories` (virgules). « shop » = tout commerce avec tag shop=*.
 * « all » est géré à part (requête prédéfinie large).
 */
export const TOKEN_TO_FILTERS: Record<string, OsmPlaceFilter[]> = {
  restaurant: [{ kind: 'amenity', value: 'restaurant' }],
  cafe: [{ kind: 'amenity', value: 'cafe' }],
  bar: [{ kind: 'amenity', value: 'bar' }],
  fast_food: [{ kind: 'amenity', value: 'fast_food' }],
  ice_cream: [{ kind: 'amenity', value: 'ice_cream' }],
  pub: [{ kind: 'amenity', value: 'pub' }],
  food_court: [{ kind: 'amenity', value: 'food_court' }],
  pharmacy: [{ kind: 'amenity', value: 'pharmacy' }],
  bank: [{ kind: 'amenity', value: 'bank' }],
  fuel: [{ kind: 'amenity', value: 'fuel' }],
  post_office: [{ kind: 'amenity', value: 'post_office' }],
  atm: [{ kind: 'amenity', value: 'atm' }],
  library: [{ kind: 'amenity', value: 'library' }],
  parking: [{ kind: 'amenity', value: 'parking' }],
  marketplace: [{ kind: 'amenity', value: 'marketplace' }],
  shop: [{ kind: 'shop_any' }],
  supermarket: [{ kind: 'shop', value: 'supermarket' }],
  bakery: [{ kind: 'shop', value: 'bakery' }],
  mall: [{ kind: 'shop', value: 'mall' }],
  convenience: [{ kind: 'shop', value: 'convenience' }],
  clothes: [{ kind: 'shop', value: 'clothes' }],
  beauty: [{ kind: 'shop', value: 'beauty' }],
  electronics: [{ kind: 'shop', value: 'electronics' }],
  hardware: [{ kind: 'shop', value: 'hardware' }],
  kiosk: [{ kind: 'shop', value: 'kiosk' }],
  hotel: [{ kind: 'tourism', value: 'hotel' }],
  guest_house: [{ kind: 'tourism', value: 'guest_house' }],
  museum: [{ kind: 'tourism', value: 'museum' }],
  attraction: [{ kind: 'tourism', value: 'attraction' }],
};

const ALL_AMENITIES_REGEX =
  'restaurant|cafe|bar|fast_food|ice_cream|pub|food_court|pharmacy|bank|fuel|post_office|atm|library|parking|marketplace';

const ALL_TOURISM_REGEX = 'hotel|guest_house|museum|attraction';

export function buildGrandTunisDefaultOverpassQuery(bb: string): string {
  return `[out:json][timeout:55];
(
  node["amenity"~"^(${ALL_AMENITIES_REGEX})$"](${bb});
  way["amenity"~"^(${ALL_AMENITIES_REGEX})$"](${bb});
  node["shop"](${bb});
  way["shop"](${bb});
  node["tourism"~"^(${ALL_TOURISM_REGEX})$"](${bb});
  way["tourism"~"^(${ALL_TOURISM_REGEX})$"](${bb});
);
out center;`;
}

export function buildOverpassQueryFromFilters(
  bb: string,
  filters: OsmPlaceFilter[],
): string {
  const amenities = new Set<string>();
  const tourism = new Set<string>();
  const shops = new Set<string>();
  let anyShop = false;

  for (const f of filters) {
    if (f.kind === 'amenity') amenities.add(f.value);
    else if (f.kind === 'tourism') tourism.add(f.value);
    else if (f.kind === 'shop_any') anyShop = true;
    else if (f.kind === 'shop') shops.add(f.value);
  }

  const lines: string[] = [];
  if (amenities.size > 0) {
    const r = [...amenities].join('|');
    lines.push(`  node["amenity"~"^(${r})$"](${bb});`);
    lines.push(`  way["amenity"~"^(${r})$"](${bb});`);
  }
  if (anyShop) {
    lines.push(`  node["shop"](${bb});`);
    lines.push(`  way["shop"](${bb});`);
  }
  for (const s of shops) {
    lines.push(`  node["shop"="${s}"](${bb});`);
    lines.push(`  way["shop"="${s}"](${bb});`);
  }
  if (tourism.size > 0) {
    const r = [...tourism].join('|');
    lines.push(`  node["tourism"~"^(${r})$"](${bb});`);
    lines.push(`  way["tourism"~"^(${r})$"](${bb});`);
  }

  return `[out:json][timeout:55];
(
${lines.join('\n')}
);
out center;`;
}
