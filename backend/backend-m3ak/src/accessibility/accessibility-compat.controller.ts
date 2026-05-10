import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { AccessibilityService } from './accessibility.service';
import { AnalyzePlaceDto } from './dto/analyze-place.dto';
import { AccessibleRouteDto, NearestNodeDto } from './dto/accessible-route.dto';

@ApiExcludeController()
@Controller()
export class AccessibilityCompatController {
  constructor(private readonly accessibilityService: AccessibilityService) {}

  @Get('health')
  getHealth() {
    return this.accessibilityService.getAccessibilityHealth();
  }

  @Get('osm-tags')
  async getOsmTags(@Query('lat') lat: string, @Query('lon') lon: string) {
    return this.accessibilityService.getOsmTagsByLatLon(
      Number(lat),
      Number(lon),
    );
  }

  @Post('analyze')
  async analyzePlace(@Body() dto: AnalyzePlaceDto) {
    return this.accessibilityService.analyzePlace(dto);
  }

  @Post('nearest_node')
  nearestNode(@Body() dto: NearestNodeDto) {
    return this.accessibilityService.nearestNode(dto.lat, dto.lon);
  }

  @Post('accessible_route_full')
  async accessibleRouteFull(@Body() dto: AccessibleRouteDto) {
    return this.accessibilityService.accessibleRouteFull(
      dto.start_node,
      dto.end_node,
    );
  }
}
