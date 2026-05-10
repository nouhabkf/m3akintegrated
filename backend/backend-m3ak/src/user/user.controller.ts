import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { randomUUID } from 'crypto';
import { UserService } from './user.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateAnimalDto } from './dto/update-animal.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from './schemas/user.schema';
import { getUploadsRoot, UPLOADS_PUBLIC_PREFIX } from '../common/upload-paths';

const storage = diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, getUploadsRoot());
  },
  filename: (_, file, cb) => {
    const ext = extname(file.originalname) || '.jpg';
    cb(null, `profile-${randomUUID()}${ext}`);
  },
});

@ApiTags('User')
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post('register')
  @ApiOperation({ summary: "Création de compte (inscription)" })
  @ApiResponse({ status: 201, description: 'Compte créé avec succès' })
  @ApiResponse({ status: 400, description: 'Données invalides' })
  @ApiResponse({ status: 409, description: 'Email déjà utilisé' })
  async register(@Body() createUserDto: CreateUserDto) {
    return this.userService.create(createUserDto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Profil de l\'utilisateur connecté' })
  @ApiResponse({ status: 200, description: 'Profil récupéré avec succès' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 404, description: 'Utilisateur non trouvé' })
  async getMe(@CurrentUser() user: UserDocument) {
    return this.userService.findOne(user._id.toString());
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mise à jour du profil' })
  @ApiResponse({ status: 200, description: 'Profil mis à jour' })
  @ApiResponse({ status: 400, description: 'Données invalides' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 404, description: 'Utilisateur non trouvé' })
  async updateMe(
    @CurrentUser() user: UserDocument,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.userService.update(user._id.toString(), updateUserDto);
  }

  @Put('animal')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour l\'animal d\'assistance' })
  @ApiResponse({ status: 200, description: 'Profil animal mis à jour' })
  @ApiResponse({ status: 400, description: 'Données invalides' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 404, description: 'Utilisateur non trouvé' })
  async updateAnimal(
    @CurrentUser() user: UserDocument,
    @Body() dto: UpdateAnimalDto,
  ) {
    return this.userService.updateAnimal(user._id.toString(), dto);
  }

  @Patch('me/location')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour ma position (localisation live)' })
  @ApiResponse({ status: 200, description: 'Position mise à jour' })
  @ApiResponse({ status: 400, description: 'Coordonnées invalides' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 404, description: 'Utilisateur non trouvé' })
  async updateMyLocation(
    @CurrentUser() user: UserDocument,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.userService.updateLocation(user._id.toString(), dto);
  }

  @Delete('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Suppression du compte' })
  @ApiResponse({ status: 200, description: 'Compte supprimé' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 404, description: 'Utilisateur non trouvé' })
  async deleteMe(@CurrentUser() user: UserDocument) {
    await this.userService.remove(user._id.toString());
    return { message: 'Compte supprimé avec succès' };
  }

  @Patch('me/photo')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('image', {
      storage,
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_, file, cb) => {
        const allowed = /jpeg|jpg|png|gif|webp/i;
        const ext = extname(file.originalname);
        if (allowed.test(ext) || allowed.test(file.mimetype)) {
          cb(null, true);
        } else {
          cb(
            new BadRequestException(
              'Type de fichier non autorisé (jpeg, png, gif, webp)',
            ) as unknown as Error,
            false,
          );
        }
      },
    }),
  )
  @ApiBearerAuth()
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        image: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiOperation({ summary: 'Upload / mise à jour de la photo de profil' })
  @ApiResponse({ status: 200, description: 'Photo mise à jour' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 404, description: 'Utilisateur non trouvé' })
  async updatePhoto(
    @CurrentUser() user: UserDocument,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('Aucun fichier fourni');
    }
    const photoPath = `${UPLOADS_PUBLIC_PREFIX}/${file.filename}`;
    return this.userService.update(user._id.toString(), {}, photoPath);
  }

  @Delete('me/photo')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Supprimer la photo de profil' })
  @ApiResponse({ status: 200, description: 'Photo supprimée' })
  @ApiResponse({ status: 401, description: 'Non authentifié' })
  @ApiResponse({ status: 404, description: 'Utilisateur non trouvé' })
  async deleteMyPhoto(@CurrentUser() user: UserDocument) {
    return this.userService.clearProfilePhoto(user._id.toString());
  }
}
