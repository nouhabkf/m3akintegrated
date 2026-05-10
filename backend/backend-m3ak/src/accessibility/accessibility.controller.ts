import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AccessibilityService } from './accessibility.service';
import { AnalyzePlaceDto } from './dto/analyze-place.dto';
import { AccessibleRouteDto, NearestNodeDto } from './dto/accessible-route.dto';

@ApiTags('Accessibility')
@Controller('accessibility')
export class AccessibilityController {
  constructor(private readonly accessibilityService: AccessibilityService) {}

  @Get('health')
  @ApiOperation({ summary: 'Healthcheck module accessibilite (compat API collegue)' })
  getHealth() {
    return this.accessibilityService.getAccessibilityHealth();
  }

  @Get('features')
  @ApiOperation({
    summary:
      'Indique si Ollama est activé, les modèles, et si le serveur Ollama répond (GET /api/tags)',
  })
  async getFeatures() {
    return this.accessibilityService.getFeatureFlagsWithOllamaPing();
  }

  @Get('osm-tags')
  @ApiOperation({
    summary: 'Recupere les tags OSM accessibilite autour d un point',
  })
  async getOsmTags(@Query('lat') lat: string, @Query('lon') lon: string) {
    return this.accessibilityService.getOsmTagsByLatLon(
      Number(lat),
      Number(lon),
    );
  }

  @Post('analyze')
  @ApiOperation({
    summary:
      'Analyse accessibilite d un lieu (fusion donnees app + OSM + commentaires)',
  })
  async analyzePlace(@Body() dto: AnalyzePlaceDto) {
    return this.accessibilityService.analyzePlace(dto);
  }

  @Post('nearest_node')
  @ApiOperation({
    summary:
      'Cree/retourne un nodeId stable depuis lat/lon (compat route accessible)',
  })
  nearestNode(@Body() dto: NearestNodeDto) {
    return this.accessibilityService.nearestNode(dto.lat, dto.lon);
  }

  @Post('accessible_route_full')
  @ApiOperation({
    summary:
      'Retourne itineraire accessible et score moyen (OSRM walk ou fallback lineaire)',
  })
  async accessibleRouteFull(@Body() dto: AccessibleRouteDto) {
    return this.accessibilityService.accessibleRouteFull(
      dto.start_node,
      dto.end_node,
    );
  }
}
