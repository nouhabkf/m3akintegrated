import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsLatitude, IsLongitude, Max, Min } from 'class-validator';

export class NearestNodeDto {
  @ApiProperty({ example: 36.8 })
  @IsLatitude()
  lat: number;

  @ApiProperty({ example: 10.18 })
  @IsLongitude()
  lon: number;
}

export class AccessibleRouteDto {
  @ApiProperty({ example: 123456789 })
  @IsInt()
  @Min(1)
  @Max(2147483647)
  start_node: number;

  @ApiProperty({ example: 123456790 })
  @IsInt()
  @Min(1)
  @Max(2147483647)
  end_node: number;
}
