import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { EmergencyContactService } from './emergency-contact.service';
import { CreateEmergencyContactDto } from './dto/create-emergency-contact.dto';
import { LinkByPhoneDto } from './dto/link-by-phone.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';
import { Role } from '../user/enums/role.enum';

@ApiTags('Emergency Contacts')
@Controller('emergency-contacts')
export class EmergencyContactController {
  constructor(private readonly emergencyContactService: EmergencyContactService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Ajouter un contact urgence (HANDICAPE uniquement)' })
  async add(@CurrentUser() user: UserDocument, @Body() dto: CreateEmergencyContactDto) {
    if (user.role !== Role.HANDICAPE) {
      throw new ForbiddenException('Réservé aux comptes bénéficiaires (HANDICAPE)');
    }
    return this.emergencyContactService.add(user._id.toString(), dto);
  }

  @Post('link-by-phone')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Lier un accompagnant par numéro (profil Ma3ak) — pour les flux SOS dans l’app accompagnant',
  })
  async linkByPhone(@CurrentUser() user: UserDocument, @Body() dto: LinkByPhoneDto) {
    if (user.role !== Role.HANDICAPE) {
      throw new ForbiddenException('Réservé aux comptes bénéficiaires (HANDICAPE)');
    }
    return this.emergencyContactService.addByPhone(
      user._id.toString(),
      dto.telephone.trim(),
    );
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mes contacts urgence' })
  async getMine(@CurrentUser() user: UserDocument) {
    return this.emergencyContactService.findByUser(user._id.toString());
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Retirer un contact urgence' })
  async remove(@CurrentUser() user: UserDocument, @Param('id') id: string) {
    return this.emergencyContactService.remove(user._id.toString(), id);
  }
}
