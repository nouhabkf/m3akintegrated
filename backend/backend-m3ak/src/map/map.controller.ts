import { Controller, Post, Get, Body, Query } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiQuery,
} from '@nestjs/swagger';
import { MapService } from './map.service';
import { GeocodeDto, ReverseGeocodeDto } from './dto/geocode.dto';
import { RouteDto } from './dto/route.dto';
import { PlacesQueryDto } from './dto/places-query.dto';

@ApiTags('Map')
@Controller('map')
export class MapController {
  constructor(private readonly mapService: MapService) {}

  @Post('geocode')
  @ApiOperation({ summary: 'Géocodage : adresse → coordonnées (OpenStreetMap Nominatim)' })
  @ApiResponse({ status: 200, description: 'Liste des résultats de géocodage' })
  @ApiResponse({ status: 400, description: 'Requête invalide ou géocodage échoué' })
  async geocode(@Body() dto: GeocodeDto) {
    return this.mapService.geocode(
      dto.query,
      dto.countrycodes,
      dto.limit ?? 5,
    );
  }

  @Get('geocode')
  @ApiOperation({ summary: 'Géocodage (GET) : adresse → coordonnées' })
  @ApiQuery({ name: 'q', description: 'Adresse ou lieu à rechercher' })
  @ApiQuery({ name: 'countrycodes', required: false, description: 'Code pays (ex: TN)' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Liste des résultats' })
  async geocodeGet(
    @Query('q') q: string,
    @Query('countrycodes') countrycodes?: string,
    @Query('limit') limit?: string,
  ) {
    if (!q?.trim()) {
      return [];
    }
    return this.mapService.geocode(
      q.trim(),
      countrycodes,
      limit ? parseInt(limit, 10) : 5,
    );
  }

  @Post('reverse-geocode')
  @ApiOperation({ summary: 'Géocodage inverse : coordonnées → adresse' })
  @ApiResponse({ status: 200, description: 'Adresse correspondante' })
  @ApiResponse({ status: 400, description: 'Coordonnées invalides' })
  async reverseGeocode(@Body() dto: ReverseGeocodeDto) {
    return this.mapService.reverseGeocode(dto.lat, dto.lon);
  }

  @Get('reverse-geocode')
  @ApiOperation({ summary: 'Géocodage inverse (GET)' })
  @ApiQuery({ name: 'lat', type: Number })
  @ApiQuery({ name: 'lon', type: Number })
  @ApiResponse({ status: 200, description: 'Adresse correspondante' })
  async reverseGeocodeGet(
    @Query('lat') lat: string,
    @Query('lon') lon: string,
  ) {
    const latNum = parseFloat(lat);
    const lonNum = parseFloat(lon);
    if (isNaN(latNum) || isNaN(lonNum)) {
      return null;
    }
    return this.mapService.reverseGeocode(latNum, lonNum);
  }

  @Post('route')
  @ApiOperation({ summary: 'Calcul d\'itinéraire (OSRM / OpenStreetMap)' })
  @ApiResponse({ status: 200, description: 'Itinéraire avec distance, durée et géométrie GeoJSON' })
  @ApiResponse({ status: 400, description: 'Points invalides ou calcul impossible' })
  async getRoute(@Body() dto: RouteDto) {
    return this.mapService.getRoute(
      dto.origin,
      dto.destination,
      dto.waypoints,
    );
  }

  @Get('places')
  @ApiOperation({
    summary:
      'Lieux (POI) dans le Grand Tunis ou une bbox — OSM Overpass (restaurants, cafés, magasins, etc.)',
  })
  @ApiResponse({
    status: 200,
    description:
      'Liste de lieux avec coordonnées, nom et tags OSM (tronquée selon limit)',
  })
  @ApiResponse({ status: 400, description: 'Bbox ou catégories invalides' })
  async searchPlaces(@Query() query: PlacesQueryDto) {
    return this.mapService.searchPlaces(query);
  }
}
