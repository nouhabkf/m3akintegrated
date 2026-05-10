import { Controller, Get, Post, Patch, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MedicalRecordService } from './medical-record.service';
import { CreateMedicalRecordDto } from './dto/create-medical-record.dto';
import { UpdateMedicalRecordDto } from './dto/update-medical-record.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';

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
}
