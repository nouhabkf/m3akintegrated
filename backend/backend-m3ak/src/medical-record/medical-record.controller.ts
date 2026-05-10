import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MedicalRecordService } from './medical-record.service';
import { CreateMedicalRecordDto } from './dto/create-medical-record.dto';
import { UpdateMedicalRecordDto } from './dto/update-medical-record.dto';
import { PublishMedicalQrDto } from './dto/publish-medical-qr.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';
import { Role } from '../user/enums/role.enum';

@ApiTags('Medical Record')
@Controller('medical-records')
export class MedicalRecordController {
  constructor(private readonly medicalRecordService: MedicalRecordService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Créer un dossier médical (HANDICAPE uniquement)' })
  async create(@Body() dto: CreateMedicalRecordDto, @CurrentUser() user: UserDocument) {
    return this.medicalRecordService.create(dto, user._id.toString());
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Récupérer mon dossier médical' })
  async getMe(@CurrentUser() user: UserDocument) {
    return this.medicalRecordService.findByUserId(user._id.toString(), user._id.toString());
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour mon dossier médical' })
  async updateMe(@CurrentUser() user: UserDocument, @Body() dto: UpdateMedicalRecordDto) {
    return this.medicalRecordService.update(user._id.toString(), dto, user._id.toString());
  }

  @Post('me/publish-qr')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Publier/synchroniser le QR médical du bénéficiaire vers les accompagnants liés',
  })
  async publishQr(
    @CurrentUser() user: UserDocument,
    @Body() dto: PublishMedicalQrDto,
  ) {
    if (user.role !== Role.HANDICAPE) {
      throw new ForbiddenException(
        'Seuls les bénéficiaires (HANDICAPE) peuvent publier leur QR médical',
      );
    }
    return this.medicalRecordService.publishQr(user._id.toString(), dto);
  }

  @Get('for-accompagnant')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Récupérer les dossiers médicaux synchronisés des bénéficiaires liés',
  })
  async getForAccompagnant(@CurrentUser() user: UserDocument) {
    return this.medicalRecordService.getForAccompagnant(user._id.toString());
  }
}
