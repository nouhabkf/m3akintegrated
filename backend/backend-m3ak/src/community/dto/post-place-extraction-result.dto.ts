import { ApiProperty } from '@nestjs/swagger';
import { PLACE_EXTRACTION_CATEGORY_VALUES } from '../enums/place-extraction-category.enum';
import { PLACE_RISK_LEVEL_VALUES } from '../enums/place-risk-level.enum';

export class PostPlaceExtractionResultDto {
  @ApiProperty()
  hasPlace: boolean;

  @ApiProperty({ required: false, nullable: true })
  placeText: string | null;

  @ApiProperty({
    enum: PLACE_EXTRACTION_CATEGORY_VALUES,
    example: 'obstacle',
  })
  category: (typeof PLACE_EXTRACTION_CATEGORY_VALUES)[number];

  @ApiProperty({ minimum: 0, maximum: 1 })
  confidence: number;

  @ApiProperty({
    enum: PLACE_RISK_LEVEL_VALUES,
    example: 'danger',
  })
  riskLevel: (typeof PLACE_RISK_LEVEL_VALUES)[number];

  @ApiProperty()
  obstaclePresent: boolean;

  @ApiProperty({ required: false, nullable: true })
  summary: string | null;

  @ApiProperty({ type: [String] })
  reasonCodes: string[];
}
