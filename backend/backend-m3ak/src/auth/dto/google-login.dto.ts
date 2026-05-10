import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleLoginDto {
  @ApiProperty({ description: 'Token ID Google OAuth2' })
  @IsString()
  @IsNotEmpty({ message: 'id_token est requis' })
  id_token: string;
}
