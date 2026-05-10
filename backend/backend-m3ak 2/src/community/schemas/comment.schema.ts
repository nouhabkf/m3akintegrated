import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type CommentDocument = Comment & Document;

@Schema({ timestamps: true, versionKey: false })
export class Comment {
  @ApiProperty({ description: 'ID du post' })
  @Prop({ type: Types.ObjectId, ref: 'Post', required: true })
  postId: Types.ObjectId;

  @ApiProperty({ description: 'ID utilisateur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'Contenu' })
  @Prop({ type: String, required: true })
  contenu: string;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const CommentSchema = SchemaFactory.createForClass(Comment);
