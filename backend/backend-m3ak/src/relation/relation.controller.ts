import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { RelationService } from './relation.service';
import { CreateRelationDto } from './dto/create-relation.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';
import { Role } from '../user/enums/role.enum';

@ApiTags('Relations handicapé-accompagnant')
@Controller('relations')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class RelationController {
  constructor(private readonly relationService: RelationService) {}

  @Post()
  @ApiOperation({
    summary: 'Créer une demande de liaison',
    description:
      "Handicapé : fournir accompagnantId. Accompagnant : fournir handicapId. La liaison est créée en EN_ATTENTE jusqu'à acceptation.",
  })
  async create(@CurrentUser() user: UserDocument, @Body() dto: CreateRelationDto) {
    return this.relationService.create(user._id.toString(), user.role, dto);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: 'Accepter une demande de liaison' })
  async accept(@CurrentUser() user: UserDocument, @Param('id') id: string) {
    return this.relationService.accept(id, user._id.toString());
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Supprimer une liaison (handicapé ou accompagnant)' })
  async remove(@CurrentUser() user: UserDocument, @Param('id') id: string) {
    return this.relationService.remove(id, user._id.toString());
  }

  @Get('me')
  @ApiOperation({
    summary: 'Mes relations',
    description:
      'Handicapé : liste de mes accompagnants (liens). Accompagnant : liste de mes handicapés (liens).',
  })
  @ApiQuery({
    name: 'acceptedOnly',
    required: false,
    description: 'true = uniquement les liaisons acceptées',
  })
  async getMyRelations(
    @CurrentUser() user: UserDocument,
    @Query('acceptedOnly') acceptedOnly?: string,
  ) {
    if (user.role !== Role.HANDICAPE && user.role !== Role.ACCOMPAGNANT) {
      return [];
    }
    return this.relationService.findMyRelations(
      user._id.toString(),
      user.role,
      acceptedOnly === 'true',
    );
  }

  @Get('me/accompagnants')
  @ApiOperation({
    summary: 'Mes accompagnants (handicapé uniquement)',
    description: 'Liste des accompagnants liés à moi (acceptés uniquement par défaut).',
  })
  @ApiQuery({ name: 'acceptedOnly', required: false })
  async getMyAccompagnants(
    @CurrentUser() user: UserDocument,
    @Query('acceptedOnly') acceptedOnly?: string,
  ) {
    if (user.role !== Role.HANDICAPE) {
      return [];
    }
    return this.relationService.findAccompagnantsByHandicape(
      user._id.toString(),
      acceptedOnly !== 'false',
    );
  }

  @Get('me/handicapes')
  @ApiOperation({
    summary: 'Mes handicapés (accompagnant uniquement)',
    description: 'Liste des handicapés que j\'accompagne (acceptés uniquement par défaut).',
  })
  @ApiQuery({ name: 'acceptedOnly', required: false })
  async getMyHandicapes(
    @CurrentUser() user: UserDocument,
    @Query('acceptedOnly') acceptedOnly?: string,
  ) {
    if (user.role !== Role.ACCOMPAGNANT) {
      return [];
    }
    return this.relationService.findHandicapesByAccompagnant(
      user._id.toString(),
      acceptedOnly !== 'false',
    );
  }

  @Get(':id')
  @ApiOperation({ summary: 'Détail d\'une relation' })
  async getOne(@CurrentUser() user: UserDocument, @Param('id') id: string) {
    return this.relationService.findById(id, user._id.toString());
  }
}
