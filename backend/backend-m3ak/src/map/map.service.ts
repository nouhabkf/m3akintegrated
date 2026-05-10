import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { PlacesQueryDto } from './dto/places-query.dto';
import {
  GRAND_TUNIS_BBOX,
  PLACES_DEFAULT_LIMIT,
  PLACES_MAX_LAT_SPAN,
  PLACES_MAX_LIMIT,
  PLACES_MAX_LON_SPAN,
  TOKEN_TO_FILTERS,
  type OsmPlaceFilter,
  buildGrandTunisDefaultOverpassQuery,
  buildOverpassQueryFromFilters,
} from './map-places.constants';

const NOMINATIM_BASE = 'https://nominatim.openstreetmap.org';
const OSRM_BASE = 'https://router.project-osrm.org';
const OVERPASS_DEFAULT = 'https://overpass-api.de/api/interpreter';
const USER_AGENT = 'Ma3ak-API/1.0 (contact@ma3ak.tn)';

export interface GeocodeResult {
  lat: number;
  lon: number;
  displayName: string;
  type: string;
  address?: Record<string, string>;
}

export interface RouteResult {
  distance: number; // mètres
  duration: number; // secondes
  geometry: {
    type: 'LineString';
    coordinates: [number, number][];
  };
  waypoints: { lat: number; lon: number }[];
}

/** Lieu OSM (POI) renvoyé par /map/places */
export interface MapPlaceResult {
  osmType: 'node' | 'way' | 'relation';
  osmId: number;
  lat: number;
  lon: number;
  name: string | null;
  /** Tag principal pour classifier (amenity, shop, tourism, …) */
  primaryKey: string | null;
  /** Valeur du tag principal (ex. restaurant, supermarket) */
  primaryValue: string | null;
  tags: Record<string, string>;
}

interface OverpassElement {
  type: 'node' | 'way' | 'relation';
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

@Injectable()
export class MapService {
  private nominatimBase: string;
  private osrmBase: string;
  private overpassUrl: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.nominatimBase =
      this.configService.get<string>('NOMINATIM_URL') || NOMINATIM_BASE;
    this.osrmBase =
      this.configService.get<string>('OSRM_URL') || OSRM_BASE;
    this.overpassUrl =
      this.configService.get<string>('OVERPASS_URL') || OVERPASS_DEFAULT;
  }

  /**
   * Lieux (POI) dans une bbox — par défaut Grand Tunis (OpenStreetMap / Overpass).
   * Catégories : restaurants, cafés, commerces (shop), hôtels, musées, etc.
   */
  async searchPlaces(dto: PlacesQueryDto): Promise<{
    bbox: { south: number; west: number; north: number; east: number };
    totalReceived: number;
    returned: number;
    places: MapPlaceResult[];
  }> {
    const bbox = this.resolvePlacesBbox(dto);
    const bb = `${bbox.south},${bbox.west},${bbox.north},${bbox.east}`;
    const limit = Math.min(
      dto.limit ?? PLACES_DEFAULT_LIMIT,
      PLACES_MAX_LIMIT,
    );
    const query = this.buildPlacesOverpassQuery(dto.categories, bb);
    let data: { elements?: OverpassElement[]; remark?: string };
    try {
      const res = await firstValueFrom(
        this.httpService.post(
          this.overpassUrl,
          `data=${encodeURIComponent(query)}`,
          {
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': USER_AGENT,
            },
            timeout: 60000,
            maxContentLength: 50 * 1024 * 1024,
            maxBodyLength: 50 * 1024 * 1024,
          },
        ),
      );
      data = res.data;
    } catch {
      throw new BadRequestException(
        'Requête des lieux échouée (Overpass). Réessayez plus tard ou réduisez la zone / les catégories.',
      );
    }

    const elements = Array.isArray(data.elements) ? data.elements : [];
    const places: MapPlaceResult[] = [];
    for (const el of elements) {
      const coords = this.overpassElementCoords(el);
      if (!coords) continue;
      const tags = el.tags ?? {};
      const { primaryKey, primaryValue } = this.pickPrimaryPlaceTag(tags);
      const name =
        tags.name ?? tags['name:fr'] ?? tags['name:ar'] ?? tags.brand ?? null;
      places.push({
        osmType: el.type,
        osmId: el.id,
        lat: coords.lat,
        lon: coords.lon,
        name,
        primaryKey,
        primaryValue,
        tags,
      });
      if (places.length >= limit) break;
    }

    return {
      bbox,
      totalReceived: elements.length,
      returned: places.length,
      places,
    };
  }

  private resolvePlacesBbox(dto: PlacesQueryDto): {
    south: number;
    west: number;
    north: number;
    east: number;
  } {
    const { south, west, north, east } = dto;
    const partial =
      [south, west, north, east].filter((v) => v !== undefined && v !== null)
        .length;
    if (partial > 0 && partial < 4) {
      throw new BadRequestException(
        'Fournir les quatre paramètres south, west, north et east, ou aucun pour le Grand Tunis par défaut.',
      );
    }
    if (partial === 0) {
      return { ...GRAND_TUNIS_BBOX };
    }
    const s = south as number;
    const w = west as number;
    const n = north as number;
    const e = east as number;
    if (s >= n || w >= e) {
      throw new BadRequestException(
        'Bbox invalide : south < north et west < east requis.',
      );
    }
    if (n - s > PLACES_MAX_LAT_SPAN || e - w > PLACES_MAX_LON_SPAN) {
      throw new BadRequestException(
        'Zone trop grande. Réduisez la bbox (limite métropolitaine).',
      );
    }
    return { south: s, west: w, north: n, east: e };
  }

  private buildPlacesOverpassQuery(
    categoriesRaw: string | undefined,
    bb: string,
  ): string {
    const tokens = this.parseCategoryTokens(categoriesRaw);
    if (tokens.includes('all') || tokens.length === 0) {
      return buildGrandTunisDefaultOverpassQuery(bb);
    }
    const filters = this.mergeFiltersFromTokens(tokens);
    if (filters.length === 0) {
      throw new BadRequestException(
        `Aucune catégorie reconnue. Jetons connus : all, ${Object.keys(TOKEN_TO_FILTERS).sort().join(', ')}`,
      );
    }
    return buildOverpassQueryFromFilters(bb, filters);
  }

  private parseCategoryTokens(categoriesRaw: string | undefined): string[] {
    if (!categoriesRaw?.trim()) return [];
    return categoriesRaw
      .split(',')
      .map((t) => t.trim().toLowerCase())
      .filter(Boolean);
  }

  private mergeFiltersFromTokens(tokens: string[]): OsmPlaceFilter[] {
    const seen = new Set<string>();
    const out: OsmPlaceFilter[] = [];
    for (const t of tokens) {
      if (t === 'all') continue;
      const list = TOKEN_TO_FILTERS[t];
      if (!list) continue;
      for (const f of list) {
        const key = JSON.stringify(f);
        if (seen.has(key)) continue;
        seen.add(key);
        out.push(f);
      }
    }
    return out;
  }

  private overpassElementCoords(
    el: OverpassElement,
  ): { lat: number; lon: number } | null {
    if (typeof el.lat === 'number' && typeof el.lon === 'number') {
      return { lat: el.lat, lon: el.lon };
    }
    if (el.center && typeof el.center.lat === 'number') {
      return { lat: el.center.lat, lon: el.center.lon };
    }
    return null;
  }

  private pickPrimaryPlaceTag(tags: Record<string, string>): {
    primaryKey: string | null;
    primaryValue: string | null;
  } {
    const keys = [
      'amenity',
      'shop',
      'tourism',
      'leisure',
      'office',
      'craft',
    ] as const;
    for (const k of keys) {
      const v = tags[k];
      if (v) return { primaryKey: k, primaryValue: v };
    }
    return { primaryKey: null, primaryValue: null };
  }

  /**
   * Géocodage : adresse → coordonnées (Nominatim / OpenStreetMap)
   */
  async geocode(query: string, countrycodes?: string, limit = 5): Promise<GeocodeResult[]> {
    const params: Record<string, string | number> = {
      q: query,
      format: 'json',
      limit,
      addressdetails: '1',
    };
    if (countrycodes) params.countrycodes = countrycodes;

    try {
      const { data } = await firstValueFrom(
        this.httpService.get(`${this.nominatimBase}/search`, {
          params,
          headers: { 'User-Agent': USER_AGENT },
          timeout: 10000,
        }),
      );

      if (!Array.isArray(data) || data.length === 0) {
        return [];
      }

      return data.map((item: Record<string, unknown>) => ({
        lat: parseFloat(item.lat as string),
        lon: parseFloat(item.lon as string),
        displayName: (item.display_name as string) || '',
        type: (item.type as string) || 'unknown',
        address: (item.address as Record<string, string>) || undefined,
      }));
    } catch (error) {
      throw new BadRequestException(
        'Géocodage échoué. Vérifiez l\'adresse ou réessayez plus tard.',
      );
    }
  }

  /**
   * Géocodage inverse : coordonnées → adresse (Nominatim)
   */
  async reverseGeocode(lat: number, lon: number): Promise<GeocodeResult | null> {
    try {
      const { data } = await firstValueFrom(
        this.httpService.get(`${this.nominatimBase}/reverse`, {
          params: { lat, lon, format: 'json', addressdetails: 1 },
          headers: { 'User-Agent': USER_AGENT },
          timeout: 10000,
        }),
      );

      if (!data) return null;

      return {
        lat: parseFloat(data.lat as string),
        lon: parseFloat(data.lon as string),
        displayName: (data.display_name as string) || '',
        type: (data.type as string) || 'unknown',
        address: (data.address as Record<string, string>) || undefined,
      };
    } catch {
      return null;
    }
  }

  /**
   * Calcul d'itinéraire (OSRM / OpenStreetMap)
   * Format OSRM : lon,lat (GeoJSON order)
   */
  async getRoute(
    origin: { lat: number; lon: number },
    destination: { lat: number; lon: number },
    waypoints?: { lat: number; lon: number }[],
  ): Promise<RouteResult> {
    const coords: string[] = [
      `${origin.lon},${origin.lat}`,
      ...(waypoints || []).map((w) => `${w.lon},${w.lat}`),
      `${destination.lon},${destination.lat}`,
    ];
    const coordinates = coords.join(';');

    try {
      const { data } = await firstValueFrom(
        this.httpService.get(`${this.osrmBase}/route/v1/driving/${coordinates}`, {
          params: { overview: 'full', geometries: 'geojson', steps: false },
          timeout: 15000,
        }),
      );

      if (data.code !== 'Ok' || !data.routes?.[0]) {
        throw new BadRequestException(
          'Impossible de calculer l\'itinéraire entre ces points.',
        );
      }

      const route = data.routes[0];
      const geometry = route.geometry;

      const waypointsRes =
        data.waypoints?.map((w: { location: [number, number] }) => ({
          lon: w.location[0],
          lat: w.location[1],
        })) ?? [origin, destination];

      return {
        distance: route.distance,
        duration: route.duration,
        geometry: {
          type: 'LineString',
          coordinates: geometry.coordinates,
        },
        waypoints: waypointsRes,
      };
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      throw new BadRequestException(
        'Calcul d\'itinéraire échoué. Vérifiez les coordonnées ou réessayez plus tard.',
      );
    }
  }
}
