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
import { FilesInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiExtraModels,
  ApiOkResponse,
} from '@nestjs/swagger';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { randomUUID } from 'crypto';
import { CommunityService } from './community.service';
import { CreatePostDto } from './dto/create-post.dto';
import { CreateHelpRequestDto } from './dto/create-help-request.dto';
import { HelpRequestsPaginatedDto } from './dto/help-requests-paginated.dto';
import { CommunityActionPlanRequestDto } from './dto/community-action-plan-request.dto';
import { HelpRequest } from './schemas/help-request.schema';
import { ValidatePostObstacleDto } from './dto/validate-post-obstacle.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserDocument } from '../user/schemas/user.schema';
import { getUploadsRoot, UPLOADS_PUBLIC_PREFIX } from '../common/upload-paths';

const postImageStorage = diskStorage({
  destination: getUploadsRoot(),
  filename: (_, file, cb) => {
    const ext = extname(file.originalname) || '.jpg';
    cb(null, `post-${randomUUID()}${ext}`);
  },
});

@ApiTags('Community')
@ApiExtraModels(HelpRequest, CreateHelpRequestDto)
@Controller('community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Post('ai/action-plan')
  @ApiOperation({
    summary:
      'Proxy IA communauté: pré-remplir create_post ou create_help_request depuis texte libre',
  })
  async actionPlan(
    @Body() body: CommunityActionPlanRequestDto,
  ) {
    return this.communityService.analyzeCommunityAction(body);
  }

  @Post('posts')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @UseInterceptors(
    FilesInterceptor('images', 10, {
      storage: postImageStorage,
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
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['contenu', 'type'],
      properties: {
        contenu: { type: 'string' },
        type: { type: 'string' },
        latitude: { type: 'number', description: 'Optionnel — carte Lieu' },
        longitude: { type: 'number' },
        dangerLevel: {
          type: 'string',
          enum: ['none', 'low', 'medium', 'critical'],
          description: 'Si critical + coords → alerte SOS zone Aide',
        },
        streamType: {
          type: 'string',
          enum: ['post', 'live', 'replay'],
          default: 'post',
        },
        isLive: { type: 'boolean', default: false },
        liveStatus: {
          type: 'string',
          enum: ['active', 'ended'],
          default: 'ended',
        },
        viewersCount: { type: 'number', default: 0, minimum: 0 },
        liveVideoUrl: { type: 'string' },
        images: {
          type: 'array',
          items: { type: 'string', format: 'binary' },
        },
      },
    },
  })
  @ApiOperation({ summary: 'Créer un post (texte + jusqu’à 10 images optionnelles)' })
  async createPost(
    @CurrentUser() user: UserDocument,
    @Body() body: CreatePostDto,
    @UploadedFiles() files?: Express.Multer.File[],
  ) {
    const paths = (files ?? []).map(
      (f) => `${UPLOADS_PUBLIC_PREFIX}/${f.filename}`,
    );
    return this.communityService.createPost(
      user._id.toString(),
      body.contenu,
      body.type,
      paths,
      {
        latitude: body.latitude,
        longitude: body.longitude,
        dangerLevel: body.dangerLevel,
        postNature: body.postNature,
        targetAudience: body.targetAudience,
        inputMode: body.inputMode,
        isForAnotherPerson: body.isForAnotherPerson,
        needsAudioGuidance: body.needsAudioGuidance,
        needsVisualSupport: body.needsVisualSupport,
        needsPhysicalAssistance: body.needsPhysicalAssistance,
        needsSimpleLanguage: body.needsSimpleLanguage,
        locationSharingMode: body.locationSharingMode,
        streamType: body.streamType,
        isLive: body.isLive,
        liveStatus: body.liveStatus,
        viewersCount: body.viewersCount,
        liveVideoUrl: body.liveVideoUrl,
      },
    );
  }

  @Post('posts/:postId/validate-obstacle')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Validation communautaire : confirmer ou infirmer qu’un obstacle signalé est toujours présent',
  })
  async validatePostObstacle(
    @Param('postId') postId: string,
    @CurrentUser() user: UserDocument,
    @Body() body: ValidatePostObstacleDto,
  ) {
    return this.communityService.validatePostObstacle(
      postId,
      user._id.toString(),
      body.confirm,
    );
  }

  @Post('posts/:postId/merci')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Remercier un signalement (toggle) — alternative positive au « Like »',
  })
  async togglePostMerci(
    @Param('postId') postId: string,
    @CurrentUser() user: UserDocument,
  ) {
    return this.communityService.togglePostMerci(postId, user._id.toString());
  }

  @Get('posts/:postId/merci-state')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'État Merci pour l’utilisateur connecté' })
  async getMerciState(
    @Param('postId') postId: string,
    @CurrentUser() user: UserDocument,
  ) {
    return this.communityService.merciStateForUser(
      postId,
      user._id.toString(),
    );
  }

  @Delete('posts/:postId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Supprimer un post (auteur du post ou administrateur)',
  })
  async deletePost(
    @Param('postId') postId: string,
    @CurrentUser() user: UserDocument,
  ) {
    return this.communityService.deletePost(postId, user._id.toString(), user.role);
  }

  @Get('posts')
  @ApiOperation({
    summary: 'Liste des posts (pagination, filtre optionnel par type)',
  })
  async getPosts(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('type') type?: string,
  ) {
    return this.communityService.getPosts(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      type,
    );
  }

  @Get('posts/for-me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Liste des posts filtrée selon le profil (HANDICAPE + typeHandicap) — smart filter',
  })
  async getPostsForMe(
    @CurrentUser() user: UserDocument,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.communityService.getPostsForViewerProfile(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
      user._id.toString(),
    );
  }

  @Post('posts/:postId/comments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Commenter un post' })
  async createComment(
    @Param('postId') postId: string,
    @CurrentUser() user: UserDocument,
    @Body() body: { contenu: string },
  ) {
    return this.communityService.createComment(postId, user._id.toString(), body.contenu);
  }

  @Get('posts/:postId/comments')
  @ApiOperation({ summary: 'Commentaires d\'un post' })
  async getComments(@Param('postId') postId: string) {
    return this.communityService.getComments(postId);
  }

  @Delete('posts/:postId/comments/:commentId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Supprimer un commentaire (auteur du commentaire, auteur du post, ou administrateur)',
  })
  async deleteComment(
    @Param('postId') postId: string,
    @Param('commentId') commentId: string,
    @CurrentUser() user: UserDocument,
  ) {
    return this.communityService.deleteComment(
      postId,
      commentId,
      user._id.toString(),
      user.role,
    );
  }

  @Get('posts/:postId/comments/flash-summary')
  @ApiOperation({ summary: 'Résumé flash des commentaires (accessibilité)' })
  async getCommentsFlashSummary(@Param('postId') postId: string) {
    return this.communityService.getCommentsFlashSummary(postId);
  }

  @Get('posts/:id')
  @ApiOperation({ summary: 'Détail d\'un post' })
  async getPost(@Param('id') id: string) {
    return this.communityService.getPost(id);
  }

  @Post('help-requests')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiBody({ type: CreateHelpRequestDto })
  @ApiOkResponse({
    type: HelpRequest,
    description:
      'Document MongoDB sauvegardé : description (texte final du message builder), urgencyScore (IA sur ce texte), ' +
      'priority, priorityScore, priorityReason, prioritySignals (HelpPriorityService), ' +
      'plus champs inclusifs optionnels (helpType, inputMode, requesterProfile, needs*, isForAnotherPerson, presetMessageKey).',
  })
  @ApiOperation({
    summary: 'Créer une demande d\'aide',
    description:
      'Flux : HelpRequestMessageBuilderService (description finale) → urgence IA → priorité métier (texte + métadonnées). ' +
      'Champs inclusifs optionnels. Les clients existants peuvent n’envoyer que description + latitude + longitude.',
  })
  async createHelpRequest(
    @CurrentUser() user: UserDocument,
    @Body() body: CreateHelpRequestDto,
  ) {
    return this.communityService.createHelpRequest(user._id.toString(), body);
  }

  @Get('help-requests')
  @ApiOkResponse({
    type: HelpRequestsPaginatedDto,
    description:
      'Tri : priorité (critical > high > medium > low), puis priorityScore décroissant, puis createdAt. ' +
      'Chaque demande inclut priority, priorityScore, priorityReason, prioritySignals lorsqu’ils sont définis.',
  })
  @ApiOperation({
    summary: 'Liste des demandes d\'aide',
    description:
      'Pagination inchangée. Ordre : niveau de priorité, puis score numérique, puis date de création.',
  })
  async getHelpRequests(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.communityService.getHelpRequests(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Post('help-requests/:id/statut')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mettre à jour le statut d\'une demande' })
  async updateHelpRequestStatut(
    @Param('id') id: string,
    @Body() body: { statut: string },
  ) {
    return this.communityService.updateHelpRequestStatut(id, body.statut);
  }

  @Patch('help-requests/:id/accept')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Accepter une demande d\'aide' })
  async acceptHelpRequest(
    @Param('id') id: string,
    @CurrentUser() user: UserDocument,
  ) {
    const helperName = `${(user.prenom ?? '').toString().trim()} ${(user.nom ?? '').toString().trim()}`.trim();
    return this.communityService.acceptHelpRequest(id, user._id.toString(), helperName);
  }
}
