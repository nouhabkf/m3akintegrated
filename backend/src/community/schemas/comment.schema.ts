import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CommentDocument = Comment & Document;

@Schema({ timestamps: true })
export class Comment {
  @Prop({ type: Types.ObjectId, ref: 'Post', required: true })
  postId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  contenu: string;

  @Prop({ default: 0 })
  likesCount: number;

  @Prop({ type: [Types.ObjectId], ref: 'User', default: [] })
  likedBy: Types.ObjectId[];
}

export const CommentSchema = SchemaFactory.createForClass(Comment);

CommentSchema.index({ postId: 1 });
CommentSchema.index({ userId: 1 });
CommentSchema.index({ createdAt: 1 });




