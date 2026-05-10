import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PostDocument = Post & Document;

export enum PostType {
  GENERAL = 'general',
  HANDICAP_MOTEUR = 'handicapMoteur',
  HANDICAP_VISUEL = 'handicapVisuel',
  HANDICAP_AUDITIF = 'handicapAuditif',
  HANDICAP_COGNITIF = 'handicapCognitif',
  CONSEIL = 'conseil',
  TEMOIGNAGE = 'temoignage',
  AUTRE = 'autre',
}

@Schema({ timestamps: true })
export class Post {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  contenu: string;

  @Prop({ type: String, enum: PostType, default: PostType.GENERAL })
  type: PostType;

  @Prop({ default: 0 })
  likesCount: number;

  @Prop({ default: 0 })
  commentsCount: number;

  @Prop({ type: [Types.ObjectId], ref: 'User', default: [] })
  likedBy: Types.ObjectId[];
}

export const PostSchema = SchemaFactory.createForClass(Post);

PostSchema.index({ userId: 1 });
PostSchema.index({ type: 1 });
PostSchema.index({ createdAt: -1 });




