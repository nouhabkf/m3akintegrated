import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { EducationService } from './education.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';

@ApiTags('Education')
@Controller('education')
export class EducationController {
  constructor(private readonly educationService: EducationService) {}

  @Get('modules')
  @ApiOperation({ summary: 'Liste des modules éducatifs' })
  async getModules(@Query('type') type?: string) {
    return this.educationService.getModules(type);
  }

  @Get('modules/:id')
  @ApiOperation({ summary: 'Détail d\'un module' })
  async getModule(@Param('id') id: string) {
    return this.educationService.getModule(id);
  }

  @Post('modules')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer un module (admin)' })
  async createModule(@Body() dto: { titre: string; type: string; niveau: string; description?: string }) {
    return this.educationService.createModule(dto);
  }

  @Get('progress')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mon progrès' })
  async getProgress(@CurrentUser() user: UserDocument) {
    return this.educationService.getProgress(user._id.toString());
  }

  @Post('progress')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour mon progrès' })
  async updateProgress(
    @CurrentUser() user: UserDocument,
    @Body() dto: { moduleId: string; score: number; niveauActuel: string },
  ) {
    return this.educationService.updateProgress(
      user._id.toString(),
      dto.moduleId,
      dto.score,
      dto.niveauActuel,
    );
  }
}
