import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AccessibilityService } from './accessibility.service';

@ApiTags('Accessibility')
@Controller('accessibility')
export class AccessibilityController {
  constructor(private readonly accessibilityService: AccessibilityService) {}

  @Get('features')
  @ApiOperation({
    summary:
      'Indique si Ollama est activé, les modèles, et si le serveur Ollama répond (GET /api/tags)',
  })
  async getFeatures() {
    return this.accessibilityService.getFeatureFlagsWithOllamaPing();
  }
}
