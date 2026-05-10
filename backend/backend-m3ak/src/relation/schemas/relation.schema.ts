import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { ApiProperty } from '@nestjs/swagger';
import { Document, Types } from 'mongoose';
import { RelationStatut } from '../enums/relation-statut.enum';

export type RelationDocument = Relation & Document;
export { RelationStatut };

@Schema({ timestamps: true, versionKey: false })
export class Relation {
  @ApiProperty({ description: 'ID de l\'utilisateur handicapé' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  handicapId: Types.ObjectId;

  @ApiProperty({ description: 'ID de l\'accompagnant' })
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  accompagnantId: Types.ObjectId;

  @ApiProperty({ enum: RelationStatut, description: 'Statut de la liaison' })
  @Prop({ type: String, enum: RelationStatut, default: RelationStatut.EN_ATTENTE })
  statut: RelationStatut;

  @ApiProperty({ description: 'Date de création' })
  createdAt?: Date;

  @ApiProperty({ description: 'Date de dernière mise à jour' })
  updatedAt?: Date;
}

export const RelationSchema = SchemaFactory.createForClass(Relation);

// Unicité : une seule liaison par couple (handicapé, accompagnant)
RelationSchema.index({ handicapId: 1, accompagnantId: 1 }, { unique: true });
RelationSchema.index({ accompagnantId: 1, handicapId: 1 });
