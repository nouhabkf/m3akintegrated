import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, PipelineStage, Types } from 'mongoose';
import { CommunityVisionService } from './community-vision.service';
import { HelpPriorityService } from '../help-priority/help-priority.service';
import type { HelpUserProfile } from '../help-priority/help-priority.types';
import { LieuService } from '../lieu/lieu.service';
import { SosAlertService } from '../sos-alert/sos-alert.service';
import { UserService } from '../user/user.service';
import { Post, PostDocument } from './schemas/post.schema';
import { Comment, CommentDocument } from './schemas/comment.schema';
import { HelpRequest, HelpRequestDocument } from './schemas/help-request.schema';
import { postTypesForHandicapProfile } from './enums/type-handicap.enum';
import type { HelpRequestRequesterProfile } from './enums/help-request-inclusion.enum';
import { Role } from '../user/enums/role.enum';
import { CreateHelpRequestDto } from './dto/create-help-request.dto';
import { HelpRequestMessageBuilderService } from './help-request-message-builder.service';
import { CommunityActionPlanRequestDto } from './dto/community-action-plan-request.dto';
import { CommunityActionPlanResponseDto } from './dto/community-action-plan-response.dto';

const TRUST_POINTS_COMMENT = 2;
const TRUST_POINTS_ACCEPT_HELP = 10;

@Injectable()
export class CommunityService {
  constructor(
    @InjectModel(Post.name) private postModel: Model<PostDocument>,
    @InjectModel(Comment.name) private commentModel: Model<CommentDocument>,
    @InjectModel(HelpRequest.name) private helpRequestModel: Model<HelpRequestDocument>,
    private readonly communityVision: CommunityVisionService,
    private readonly lieuService: LieuService,
    private readonly sosAlertService: SosAlertService,
    private readonly userService: UserService,
    private readonly helpPriorityService: HelpPriorityService,
    private readonly helpRequestMessageBuilder: HelpRequestMessageBuilderService,
    private readonly configService: ConfigService,
  ) {}

  async analyzeCommunityAction(
    dto: CommunityActionPlanRequestDto,
  ): Promise<CommunityActionPlanResponseDto> {
    const base =
      this.configService.get<string>('AI_COMMUNITY_BASE_URL') ??
      'http://127.0.0.1:8000';
    const url = `${base.replace(/\/$/, '')}/ai/community/action-plan`;
    const timeoutMs = Number(
      this.configService.get<string>('AI_COMMUNITY_TIMEOUT_MS') ?? '10000',
    );

    let response: Response;
    try {
      response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(dto),
        signal: AbortSignal.timeout(
          Number.isFinite(timeoutMs) ? timeoutMs : 10000,
        ),
      });
    } catch (e) {
      throw new ServiceUnavailableException(
        `Community AI unreachable (${url}): ${String(e)}`,
      );
    }

    if (!response.ok) {
      const txt = await response.text();
      throw new ServiceUnavailableException(
        `Community AI HTTP ${response.status}: ${txt.slice(0, 300)}`,
      );
    }

    const data =
      (await response.json()) as CommunityActionPlanResponseDto;
    return data;
  }

  /** Mappe le profil utilisateur vers le type attendu par HelpPriorityService. */
  /** Priorité : profil explicite dans la demande, sinon profil utilisateur. */
  private mapRequesterProfileToHelpPriority(
    p: HelpRequestRequesterProfile | undefined,
  ): HelpUserProfile | undefined {
    if (!p || p === 'unknown') return undefined;
    const m: Record<string, HelpUserProfile> = {
      visual: 'visual',
      motor: 'motor',
      hearing: 'hearing',
      cognitive: 'cognitive',
      caregiver: 'caregiver',
    };
    return m[p];
  }

  private mapToHelpUserProfile(
    role: string | undefined | null,
    typeHandicap: string | null | undefined,
  ): HelpUserProfile | undefined {
    if (role && String(role).toUpperCase() === Role.ACCOMPAGNANT) {
      return 'caregiver';
    }
    if (!typeHandicap?.trim()) return undefined;
    const t = typeHandicap.toLowerCase();
    if (t.includes('visuel') || t.includes('visual') || t === 'vis') return 'visual';
    if (t.includes('moteur')) return 'motor';
    if (t.includes('auditif')) return 'hearing';
    if (t.includes('cognitif')) return 'cognitive';
    return undefined;
  }

  // Posts
  async createPost(
    userId: string,
    contenu: string,
    type: string,
    imagePaths: string[] = [],
    opts?: {
      latitude?: number;
      longitude?: number;
      dangerLevel?: string;
      postNature?: string;
      targetAudience?: string;
      inputMode?: string;
      isForAnotherPerson?: boolean;
      needsAudioGuidance?: boolean;
      needsVisualSupport?: boolean;
      needsPhysicalAssistance?: boolean;
      needsSimpleLanguage?: boolean;
      locationSharingMode?: string;
      streamType?: string;
      isLive?: boolean;
      liveStatus?: string;
      viewersCount?: number;
      liveVideoUrl?: string;
    },
  ) {
    const dangerLevel = opts?.dangerLevel ?? 'none';
    const streamType = opts?.streamType ?? 'post';
    const isLive = opts?.isLive ?? streamType === 'live';
    const liveStatus = opts?.liveStatus ?? (isLive ? 'active' : 'ended');
    const viewersCount = Math.max(0, opts?.viewersCount ?? 0);

    let useLat = opts?.latitude;
    let useLng = opts?.longitude;
    const locMode = opts?.locationSharingMode;
    if (locMode === 'none') {
      useLat = undefined;
      useLng = undefined;
    } else if (
      locMode === 'approximate' &&
      useLat != null &&
      useLng != null &&
      Number.isFinite(useLat) &&
      Number.isFinite(useLng)
    ) {
      useLat = Math.round(useLat * 1000) / 1000;
      useLng = Math.round(useLng * 1000) / 1000;
    }

    const extraction = await this.communityVision.extractPlaceFromPost({
      contenu,
      dangerLevel,
      latitude: useLat,
      longitude: useLng,
      hasImages: imagePaths.length > 0,
    });

    const hasCoords =
      useLat != null &&
      useLng != null &&
      Number.isFinite(useLat) &&
      Number.isFinite(useLng);

    let placeVerificationStatus = 'none';
    if (extraction.hasPlace && hasCoords) {
      // Avec position partagée, on crée au minimum une entrée "pending" dans Lieux.
      if (extraction.confidence >= 0.85) {
        placeVerificationStatus = extraction.obstaclePresent ? 'auto' : 'verified';
      } else {
        placeVerificationStatus = 'pending';
      }
    } else if (extraction.hasPlace && extraction.confidence >= 0.6) {
      placeVerificationStatus = 'pending';
    }

    const post = await this.postModel.create({
      userId: new Types.ObjectId(userId),
      contenu,
      type,
      images: imagePaths,
      latitude: useLat,
      longitude: useLng,
      dangerLevel,
      validationYes: 0,
      validationNo: 0,
      hasPlace: extraction.hasPlace,
      placeText: extraction.placeText,
      placeCategory: extraction.category,
      placeConfidence: extraction.confidence,
      riskLevel: extraction.riskLevel,
      obstaclePresent: extraction.obstaclePresent,
      aiSummary: extraction.summary,
      reasonCodes: extraction.reasonCodes,
      placeVerificationStatus,
      merciCount: 0,
      merciUserIds: [],
      obstacleVoterIds: [],
      postNature: opts?.postNature ?? null,
      targetAudience: opts?.targetAudience ?? null,
      inputMode: opts?.inputMode ?? null,
      isForAnotherPerson: opts?.isForAnotherPerson ?? null,
      needsAudioGuidance: opts?.needsAudioGuidance ?? null,
      needsVisualSupport: opts?.needsVisualSupport ?? null,
      needsPhysicalAssistance: opts?.needsPhysicalAssistance ?? null,
      needsSimpleLanguage: opts?.needsSimpleLanguage ?? null,
      locationSharingMode: opts?.locationSharingMode ?? null,
      streamType,
      isLive,
      liveStatus,
      viewersCount,
      liveVideoUrl: opts?.liveVideoUrl ?? null,
    });

    /** Pont Post (danger critique) → alerte SOS pour utilisateurs à proximité (API findNearby). */
    if (
      dangerLevel === 'critical' &&
      useLat != null &&
      useLng != null &&
      Number.isFinite(useLat) &&
      Number.isFinite(useLng)
    ) {
      await this.sosAlertService.create(userId, {
        latitude: useLat,
        longitude: useLng,
      });
    }

    // Injection automatique / pending vers Lieux selon seuils.
    if (
      extraction.hasPlace &&
      hasCoords &&
      (placeVerificationStatus === 'auto' ||
        placeVerificationStatus === 'pending' ||
        placeVerificationStatus === 'verified')
    ) {
      const linkedLieu = await this.lieuService.upsertFromCommunitySignal({
        nom: extraction.placeText || 'Lieu signalé',
        adresse: extraction.placeText || 'Adresse à préciser',
        latitude: useLat!,
        longitude: useLng!,
        typeLieu: 'OTHER',
        riskLevel: extraction.obstaclePresent ? 'danger' : extraction.riskLevel,
        verificationStatus:
          placeVerificationStatus === 'auto'
            ? 'auto'
            : placeVerificationStatus === 'pending'
            ? 'pending'
            : 'verified',
        obstaclePresent: extraction.obstaclePresent,
        aiConfidence: extraction.confidence,
        aiSummary:
          extraction.obstaclePresent
            ? extraction.summary || 'Obstacle signalé par la communauté.'
            : extraction.summary || contenu,
        sourcePostId: post._id.toString(),
      });
      if (linkedLieu) {
        post.linkedLieuId = linkedLieu._id as Types.ObjectId;
        await post.save();
      }
    }

    return post;
  }

  /** Validation communautaire : l’obstacle signalé est-il toujours là ? (un vote par utilisateur) */
  async validatePostObstacle(postId: string, userId: string, confirm: boolean) {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post non trouvé');
    const uid = new Types.ObjectId(userId);
    const voters = post.obstacleVoterIds ?? [];
    if (voters.some((id) => id.equals(uid))) {
      throw new BadRequestException(
        'Vous avez déjà participé à cette validation',
      );
    }
    const inc = confirm ? { validationYes: 1 } : { validationNo: 1 };
    return this.postModel
      .findByIdAndUpdate(
        postId,
        { $inc: inc, $push: { obstacleVoterIds: uid } },
        { new: true },
      )
      .populate('userId', '-password')
      .exec();
  }

  /** « Merci » — remplace le Like ; un clic par utilisateur (toggle). */
  async togglePostMerci(postId: string, userId: string) {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post non trouvé');
    const authorId = post.userId as Types.ObjectId;
    const uid = new Types.ObjectId(userId);
    if (authorId.equals(uid)) {
      throw new BadRequestException(
        'Vous ne pouvez pas vous remercier pour votre propre signalement',
      );
    }
    const ids = post.merciUserIds ?? [];
    const already = ids.some((id) => id.equals(uid));
    if (already) {
      const updated = await this.postModel
        .findByIdAndUpdate(
          postId,
          {
            $pull: { merciUserIds: uid },
            $inc: { merciCount: -1 },
          },
          { new: true },
        )
        .populate('userId', '-password')
        .exec();
      if (updated && updated.merciCount < 0) {
        await this.postModel.updateOne({ _id: post._id }, { $set: { merciCount: 0 } });
        updated.merciCount = 0;
      }
      return {
        post: updated,
        thankReceivedFromMe: false,
        merciCount: updated?.merciCount ?? 0,
      };
    }
    const updated = await this.postModel
      .findByIdAndUpdate(
        postId,
        {
          $addToSet: { merciUserIds: uid },
          $inc: { merciCount: 1 },
        },
        { new: true },
      )
      .populate('userId', '-password')
      .exec();
    return {
      post: updated,
      thankReceivedFromMe: true,
      merciCount: updated?.merciCount ?? 0,
    };
  }

  merciStateForUser(postId: string, userId: string) {
    return this.postModel
      .findById(postId)
      .select('merciCount merciUserIds userId')
      .lean()
      .exec()
      .then((doc) => {
        if (!doc) throw new NotFoundException('Post non trouvé');
        const uid = new Types.ObjectId(userId);
        const ids = (doc as { merciUserIds?: Types.ObjectId[] }).merciUserIds ?? [];
        const thankReceivedFromMe = ids.some((id) => id.equals(uid));
        const authorId = (doc as { userId: Types.ObjectId }).userId;
        const isOwn =
          authorId && new Types.ObjectId(authorId).equals(uid);
        return {
          merciCount: (doc as { merciCount?: number }).merciCount ?? 0,
          thankReceivedFromMe: isOwn ? false : thankReceivedFromMe,
        };
      });
  }

  private isAdminRole(role?: string | null): boolean {
    return (role ?? '').toString().toUpperCase() === Role.ADMIN;
  }

  async deletePost(postId: string, actorUserId: string, actorRole?: string | null) {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post non trouvé');
    const isOwner = post.userId.toString() === actorUserId;
    if (!isOwner && !this.isAdminRole(actorRole)) {
      throw new ForbiddenException(
        'Seul l’auteur du post (ou un administrateur) peut supprimer ce post',
      );
    }
    await this.commentModel.deleteMany({
      postId: new Types.ObjectId(postId),
    });
    await this.postModel.findByIdAndDelete(postId).exec();
    return { deleted: true, id: postId };
  }

  async deleteComment(
    postId: string,
    commentId: string,
    actorUserId: string,
    actorRole?: string | null,
  ) {
    const [post, comment] = await Promise.all([
      this.postModel.findById(postId).select('_id userId').exec(),
      this.commentModel.findById(commentId).select('_id postId userId').exec(),
    ]);

    if (!post) throw new NotFoundException('Post non trouvé');
    if (!comment) throw new NotFoundException('Commentaire non trouvé');
    if (comment.postId.toString() !== postId) {
      throw new BadRequestException('Le commentaire ne correspond pas à ce post');
    }

    const isCommentAuthor = comment.userId.toString() === actorUserId;
    const isPostOwner = post.userId.toString() === actorUserId;
    const isAdmin = this.isAdminRole(actorRole);
    if (!isCommentAuthor && !isPostOwner && !isAdmin) {
      throw new ForbiddenException(
        'Suppression refusée: auteur du commentaire, auteur du post ou administrateur uniquement',
      );
    }

    await this.commentModel.findByIdAndDelete(commentId).exec();
    return { deleted: true, id: commentId };
  }

  async getPosts(page = 1, limit = 20, type?: string) {
    const skip = (page - 1) * limit;
    const filter: Record<string, unknown> = {};
    if (type?.trim()) {
      filter.type = type.trim();
    }
    const [data, total] = await Promise.all([
      this.postModel
        .find(filter)
        .populate('userId', '-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.postModel.countDocuments(filter).exec(),
    ]);
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  /**
   * Filtre intelligent selon `role` + `typeHandicap` (Enums côté API, alignés Flutter).
   */
  async getPostsForViewerProfile(page = 1, limit = 20, viewerUserId: string) {
    const user = await this.userService.findOne(viewerUserId);
    const types = postTypesForHandicapProfile(
      user.role as string,
      user.typeHandicap as string | null,
    );
    const skip = (page - 1) * limit;
    const filter: Record<string, unknown> = {};
    if (types.length > 0) {
      filter.type = { $in: types };
    }
    const [data, total] = await Promise.all([
      this.postModel
        .find(filter)
        .populate('userId', '-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.postModel.countDocuments(filter).exec(),
    ]);
    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      matchedTypes: types,
    };
  }

  async getPost(id: string) {
    const post = await this.postModel.findById(id).populate('userId', '-password').exec();
    if (!post) throw new NotFoundException('Post non trouvé');
    return post;
  }

  // Comments
  async createComment(postId: string, userId: string, contenu: string) {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post non trouvé');
    const comment = await this.commentModel.create({
      postId: new Types.ObjectId(postId),
      userId: new Types.ObjectId(userId),
      contenu,
    });
    await this.userService.addTrustPoints(userId, TRUST_POINTS_COMMENT);
    return comment;
  }

  async getComments(postId: string) {
    return this.commentModel
      .find({ postId: new Types.ObjectId(postId) })
      .populate('userId', '-password')
      .sort({ createdAt: 1 })
      .exec();
  }

  async getCommentsFlashSummary(postId: string) {
    const post = await this.postModel.findById(postId).exec();
    if (!post) throw new NotFoundException('Post non trouvé');
    const comments = await this.commentModel
      .find({ postId: new Types.ObjectId(postId) })
      .select('contenu')
      .lean()
      .exec();
    const texts = comments.map((c) => String((c as { contenu: string }).contenu ?? ''));
    return this.communityVision.flashSummaryFromComments(texts);
  }

  // Help Requests
  async createHelpRequest(userId: string, dto: CreateHelpRequestDto) {
    const finalDescription = this.helpRequestMessageBuilder.buildFinalDescription({
      description: dto.description,
      helpType: dto.helpType,
      inputMode: dto.inputMode,
      requesterProfile: dto.requesterProfile,
      needsAudioGuidance: dto.needsAudioGuidance,
      needsVisualSupport: dto.needsVisualSupport,
      needsPhysicalAssistance: dto.needsPhysicalAssistance,
      needsSimpleLanguage: dto.needsSimpleLanguage,
      isForAnotherPerson: dto.isForAnotherPerson,
      presetMessageKey: dto.presetMessageKey,
    });

    const [urgencyScore, user] = await Promise.all([
      this.communityVision.getUrgencyScore(finalDescription),
      this.userService.findOne(userId),
    ]);
    const hour = new Date().getHours();
    const userProfile =
      this.mapRequesterProfileToHelpPriority(dto.requesterProfile) ??
      this.mapToHelpUserProfile(user.role, user.typeHandicap);
    const priorityResult = this.helpPriorityService.computePriority({
      text: finalDescription,
      hasAcceptedHelper: false,
      waitingMinutes: 0,
      hour,
      userProfile,
      helpType: dto.helpType,
      inputMode: dto.inputMode,
      declaredRequesterProfile: dto.requesterProfile,
      isForAnotherPerson: dto.isForAnotherPerson,
      needsAudioGuidance: dto.needsAudioGuidance,
      needsVisualSupport: dto.needsVisualSupport,
      needsPhysicalAssistance: dto.needsPhysicalAssistance,
      needsSimpleLanguage: dto.needsSimpleLanguage,
    });
    return this.helpRequestModel.create({
      userId: new Types.ObjectId(userId),
      description: finalDescription,
      latitude: dto.latitude,
      longitude: dto.longitude,
      statut: 'EN_ATTENTE',
      urgencyScore,
      priority: priorityResult.priority,
      priorityScore: priorityResult.score,
      priorityReason: priorityResult.reason,
      prioritySignals: priorityResult.matchedSignals,
      helpType: dto.helpType ?? null,
      inputMode: dto.inputMode ?? null,
      requesterProfile: dto.requesterProfile ?? null,
      needsAudioGuidance: dto.needsAudioGuidance ?? null,
      needsVisualSupport: dto.needsVisualSupport ?? null,
      needsPhysicalAssistance: dto.needsPhysicalAssistance ?? null,
      needsSimpleLanguage: dto.needsSimpleLanguage ?? null,
      isForAnotherPerson: dto.isForAnotherPerson ?? null,
      presetMessageKey: dto.presetMessageKey ?? null,
    });
  }

  /**
   * Liste paginée : priorité (critical → low), puis score décroissant, puis date.
   * Les documents sans `priority` / `priorityScore` (anciennes données) sont en queue.
   */
  async getHelpRequests(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const pipeline: PipelineStage[] = [
      {
        $addFields: {
          _priorityRank: {
            $switch: {
              branches: [
                { case: { $eq: ['$priority', 'critical'] }, then: 4 },
                { case: { $eq: ['$priority', 'high'] }, then: 3 },
                { case: { $eq: ['$priority', 'medium'] }, then: 2 },
                { case: { $eq: ['$priority', 'low'] }, then: 1 },
              ],
              default: 0,
            },
          },
          _scoreSort: {
            $ifNull: ['$priorityScore', Number.MIN_SAFE_INTEGER],
          },
        },
      },
      { $sort: { _priorityRank: -1, _scoreSort: -1, createdAt: -1 } },
      { $skip: skip },
      { $limit: limit },
      {
        $lookup: {
          from: 'users',
          let: { uid: '$userId' },
          pipeline: [
            { $match: { $expr: { $eq: ['$_id', '$$uid'] } } },
            { $project: { password: 0 } },
          ],
          as: '_populatedUser',
        },
      },
      {
        $set: {
          userId: { $arrayElemAt: ['$_populatedUser', 0] },
        },
      },
      { $unset: ['_populatedUser', '_priorityRank', '_scoreSort'] },
    ];

    const [data, total] = await Promise.all([
      this.helpRequestModel.aggregate(pipeline).exec(),
      this.helpRequestModel.countDocuments().exec(),
    ]);
    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateHelpRequestStatut(id: string, statut: string) {
    const hr = await this.helpRequestModel.findByIdAndUpdate(id, { $set: { statut } }, { new: true }).exec();
    if (!hr) throw new NotFoundException('Demande non trouvée');
    return hr;
  }

  async acceptHelpRequest(id: string, acceptedBy: string, helperName: string) {
    const existing = await this.helpRequestModel.findById(id).exec();
    if (!existing) throw new NotFoundException('Demande non trouvée');
    if (existing.statut !== 'EN_ATTENTE') {
      throw new BadRequestException('Cette demande ne peut plus être acceptée');
    }

    const hr = await this.helpRequestModel
      .findByIdAndUpdate(
        id,
        {
          $set: {
            statut: 'EN_COURS',
            acceptedBy: new Types.ObjectId(acceptedBy),
            helperName,
          },
        },
        { new: true },
      )
      .exec();

    if (!hr) throw new NotFoundException('Demande non trouvée');
       await this.userService.addTrustPoints(acceptedBy, TRUST_POINTS_ACCEPT_HELP);
    return hr;
  }
}
