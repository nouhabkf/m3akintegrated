import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AccessibilityModule } from '../accessibility/accessibility.module';
import { LieuModule } from '../lieu/lieu.module';
import { SosAlertModule } from '../sos-alert/sos-alert.module';
import { UserModule } from '../user/user.module';
import { CommunityController } from './community.controller';
import { CommunityService } from './community.service';
import { CommunityVisionService } from './community-vision.service';
import { HelpRequestMessageBuilderService } from './help-request-message-builder.service';
import { HelpPriorityModule } from '../help-priority/help-priority.module';
import { Post, PostSchema } from './schemas/post.schema';
import { Comment, CommentSchema } from './schemas/comment.schema';
import { HelpRequest, HelpRequestSchema } from './schemas/help-request.schema';

@Module({
  imports: [
    AccessibilityModule,
    LieuModule,
    SosAlertModule,
    UserModule,
    HelpPriorityModule,
    MongooseModule.forFeature([
      { name: Post.name, schema: PostSchema },
      { name: Comment.name, schema: CommentSchema },
      { name: HelpRequest.name, schema: HelpRequestSchema },
    ]),
  ],
  controllers: [CommunityController],
  providers: [
    CommunityService,
    CommunityVisionService,
    HelpRequestMessageBuilderService,
  ],
  exports: [CommunityService, CommunityVisionService],
})
export class CommunityModule {}
