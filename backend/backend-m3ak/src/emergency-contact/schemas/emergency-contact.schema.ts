import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';

export type EmergencyContactDocument = EmergencyContact & Document;

@Schema({ timestamps: false, versionKey: false })
export class EmergencyContact {
  @ApiProperty({ description: 'ID utilisateur HANDICAPE' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @ApiProperty({ description: 'ID accompagnant' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  accompagnantId: Types.ObjectId;

  @ApiProperty({ description: 'Ordre de priorité (1 = premier contacté)' })
  @Prop({ type: Number, required: true, default: 1 })
  ordrePriorite: number;
}

export const EmergencyContactSchema = SchemaFactory.createForClass(EmergencyContact);
