import { IsEnum } from 'class-validator';
import { HelpRequestStatus } from '../schemas/help-request.schema';

export class UpdateHelpRequestStatusDto {
  @IsEnum(HelpRequestStatus)
  statut: HelpRequestStatus;
}




