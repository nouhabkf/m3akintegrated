import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type NotificationDocument = Notification & Document;

@Schema({ timestamps: true, versionKey: false })
export class Notification {
  @ApiProperty({ description: 'ID utilisateur' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'Titre' })
  @Prop({ type: String, required: true })
  titre: string;

  @ApiProperty({ description: 'Message' })
  @Prop({ type: String, required: true })
  message: string;

  @ApiProperty({ description: 'Type de notification' })
  @Prop({ type: String, required: true })
  type: string;

  @ApiProperty({ description: 'Lu', default: false })
  @Prop({ type: Boolean, default: false })
  lu: boolean;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);
