import { ApiProperty } from '@nestjs/swagger';
import { HelpRequest } from '../schemas/help-request.schema';

/**
 * Réponse GET /community/help-requests (liste triée par priorité).
 * Chaque élément inclut les champs {@link HelpRequest} (dont priorité calculée).
 */
export class HelpRequestsPaginatedDto {
  @ApiProperty({ type: [HelpRequest], description: 'Demandes triées : critical → low, puis score, puis date' })
  data: HelpRequest[];

  @ApiProperty()
  total: number;

  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  totalPages: number;
}
