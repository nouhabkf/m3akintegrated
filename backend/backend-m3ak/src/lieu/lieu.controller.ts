import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes } from '@nestjs/swagger';
import { FilesInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { randomUUID } from 'crypto';
import { LieuService } from './lieu.service';
import { CreateLieuDto } from './dto/create-lieu.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { getUploadsRoot } from '../common/upload-paths';

const lieuImageStorage = diskStorage({
  destination: getUploadsRoot(),
  filename: (_, file, cb) => {
    const ext = extname(file.originalname) || '.jpg';
    cb(null, `lieu-${randomUUID()}${ext}`);
  },
});

@ApiTags('Lieux')
@Controller('lieux')
export class LieuController {
  constructor(private readonly lieuService: LieuService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(
    FilesInterceptor('images', 10, {
      storage: lieuImageStorage,
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_, file, cb) => {
        const allowed = /jpeg|jpg|png|gif|webp/i;
        const ext = extname(file.originalname);
        if (allowed.test(ext) || allowed.test(file.mimetype)) {
          cb(null, true);
        } else {
          cb(new Error('Type de fichier non autorisé'), false);
        }
      },
    }),
  )
  @ApiOperation({ summary: 'Créer un lieu (admin, images optionnelles)' })
  async create(
    @Body() dto: CreateLieuDto,
    @UploadedFiles() files?: Express.Multer.File[],
  ) {
    const imageFilenames = (files ?? []).map((f) => f.filename);
    return this.lieuService.create(dto, imageFilenames);
  }

  @Get()
  @ApiOperation({ summary: 'Liste des lieux (pagination)' })
  async findAll(
    @Query('typeLieu') typeLieu?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.lieuService.findAll({
      typeLieu,
      page: page ? parseInt(page, 10) : undefined,
      limit: limit ? parseInt(limit, 10) : undefined,
    });
  }

  @Get('nearby')
  @ApiOperation({ summary: 'Lieux à proximité (géolocalisation)' })
  async findNearby(
    @Query('latitude') latitude: string,
    @Query('longitude') longitude: string,
    @Query('maxDistance') maxDistance?: string,
  ) {
    return this.lieuService.findNearby(
      parseFloat(latitude),
      parseFloat(longitude),
      maxDistance ? parseInt(maxDistance, 10) : 50_000,
    );
  }

  @Get(':id')
  @ApiOperation({ summary: "Détail d'un lieu" })
  async findOne(@Param('id') id: string) {
    return this.lieuService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Modifier un lieu' })
  async update(@Param('id') id: string, @Body() dto: Partial<CreateLieuDto>) {
    return this.lieuService.update(id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Supprimer un lieu' })
  async remove(@Param('id') id: string) {
    await this.lieuService.remove(id);
    return { message: 'Lieu supprimé' };
  }
}
