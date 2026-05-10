import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SosAlertRecipientDocument = SosAlertRecipient & Document;

@Schema({ timestamps: true, versionKey: false })
export class SosAlertRecipient {
  @Prop({ type: Types.ObjectId, ref: 'SosAlert', required: true })
  alertId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  accompagnantId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  beneficiaryId: Types.ObjectId;

  @Prop({ type: Date, required: true, default: () => new Date() })
  notifiedAt: Date;

  createdAt?: Date;
  updatedAt?: Date;
}

export const SosAlertRecipientSchema =
  SchemaFactory.createForClass(SosAlertRecipient);

SosAlertRecipientSchema.index({ alertId: 1, accompagnantId: 1 }, { unique: true });
SosAlertRecipientSchema.index({ accompagnantId: 1, createdAt: -1 });
